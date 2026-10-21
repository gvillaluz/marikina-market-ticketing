import assert from "node:assert/strict";
import fs from "node:fs";
import test from "node:test";
import vm from "node:vm";
import ts from "typescript";

function load(file, mocks = {}, globals = {}) {
  const module = { exports: {} };
  const code = ts.transpileModule(
    fs.readFileSync(new URL(file, import.meta.url), "utf8"),
    {
      compilerOptions: {
        module: ts.ModuleKind.CommonJS,
        target: ts.ScriptTarget.ES2022,
        esModuleInterop: true,
      },
    },
  ).outputText;
  vm.runInNewContext(code, {
    module,
    exports: module.exports,
    Error,
    URL,
    URLSearchParams,
    Notification: { permission: "granted" },
    window: { location: { origin: "https://example.test" } },
    navigator: { serviceWorker: { register: async () => ({}) } },
    ...globals,
    require: (id) => {
      assert.ok(id in mocks, `Missing mock: ${id}`);
      return { __esModule: true, ...mocks[id] };
    },
  });
  return module.exports;
}

const routes = load("../../routes/routePaths.ts");
const roles = load("../../api/types/common.types.ts");
const utils = load("./notification.utils.ts", {
  "@/routes/routePaths": routes,
});
const data = { type: "vendor_registration", registration_id: "42" };
const message = { data, messageId: "message-1" };
const options = {
  user: { userId: 7, role: "HeadAdmin" },
  isAuthReady: true,
  isAuthenticated: true,
};
const tick = () => new Promise((resolve) => setImmediate(resolve));

function harness(failSetup = false) {
  let dependencies,
    cleanup,
    cursor = 0;
  const refs = [],
    listeners = new Set(),
    toasts = [],
    navigations = [];
  let navigate = (path) => navigations.push(["initial", path]);
  let registrations = 0,
    initializations = 0,
    logoutCalls = 0;
  const workerListeners = new Set();
  const visibilityListeners = new Set();
  const document = {
    visibilityState: "visible",
    addEventListener: (_type, callback) => visibilityListeners.add(callback),
    removeEventListener: (_type, callback) =>
      visibilityListeners.delete(callback),
  };
  const api = load(
    "./hooks/useAdminPushNotifications.ts",
    {
      react: {
        useRef: (initial) => {
          const index = cursor++;
          return (refs[index] ??= { current: initial });
        },
        useEffect: (effect, next) => {
          if (
            !dependencies ||
            next.some((value, i) => value !== dependencies[i])
          ) {
            cleanup?.();
            dependencies = next;
            cleanup = effect();
          }
        },
      },
      "react-router-dom": { useNavigate: () => navigate },
      "@/api/types/common.types": roles,
      "@/api/endpoints/userDeviceToken.api": {
        userDeviceTokenApi: {
          register: async () => {
            registrations++;
          },
        },
      },
      "@/api/endpoints/auth.api": {
        authApi: {
          logout: async () => {
            logoutCalls++;
          },
        },
      },
      "@/config/env": {
        default: { firebase: {} },
        isFirebasePushConfigured: true,
      },
      "@/components/ui/Toast/useToast": {
        useToast: () => ({ showToast: (toast) => toasts.push(toast) }),
      },
      "@/utils/apiErrors": {
        ApiRequestError: class extends Error {},
        getApiErrorMessage: (_error, fallback) => fallback,
      },
      "../firebaseMessaging": {
        getBrowserMessaging: async () => {
          initializations++;
          if (failSetup) throw new Error("push service error");
          return {};
        },
        getBrowserPushToken: async () => "test-device-token",
        subscribeToMessages: async (_messaging, callback) => {
          listeners.add(callback);
          return () => listeners.delete(callback);
        },
      },
      "../notification.utils": utils,
    },
    {
      document,
      navigator: {
        serviceWorker: {
          register: async () => ({}),
          addEventListener: (_type, callback) => workerListeners.add(callback),
          removeEventListener: (_type, callback) =>
            workerListeners.delete(callback),
        },
      },
    },
  );
  return {
    render(value = options) {
      cursor = 0;
      api.useAdminPushNotifications(value);
    },
    emit(payload) {
      for (const callback of listeners) callback(payload);
    },
    background(
      payload,
      scriptURL = "https://example.test/firebase-messaging-sw.js?appId=test",
    ) {
      for (const callback of workerListeners)
        callback({
          source: { scriptURL },
          data: { type: "vendor-registration-push", payload },
        });
    },
    visibility(value) {
      document.visibilityState = value;
      for (const callback of visibilityListeners) callback();
    },
    workerListeners,
    visibilityListeners,
    setNavigation(callback) {
      navigate = callback;
    },
    resetEffect() {
      cleanup?.();
      cleanup = undefined;
      dependencies = undefined;
    },
    stop() {
      cleanup?.();
    },
    logout: api.logoutBrowserPushNotifications,
    listeners,
    toasts,
    navigations,
    get registrations() {
      return registrations;
    },
    get initializations() {
      return initializations;
    },
    get logoutCalls() {
      return logoutCalls;
    },
  };
}

test("message IDs distinguish new deliveries and absent IDs fall back to the registration", () => {
  assert.equal(
    utils.getVendorRegistrationPushKey(data, " message-1 "),
    "message:message-1",
  );
  assert.notEqual(
    utils.getVendorRegistrationPushKey(data, "message-1"),
    utils.getVendorRegistrationPushKey(data, "message-2"),
  );
  assert.equal(
    utils.getVendorRegistrationPushKey(data),
    utils.getVendorRegistrationPushKey(data, ""),
  );
  assert.equal(
    utils.getVendorRegistrationPushKey(
      { ...data, registration_id: "42/other" },
      "x",
    ),
    null,
  );
  assert.equal(
    utils.getVendorRegistrationPushKey({ ...data, type: "other" }, "x"),
    null,
  );
});

test("navigation and profile refreshes keep one listener and do not repeat registration or notifications", async () => {
  const h = harness();
  h.render();
  await tick();
  h.emit(message);
  h.setNavigation((path) => h.navigations.push(["tickets", path]));
  h.render({ ...options, user: { ...options.user, firstName: "Updated" } });
  await tick();
  h.emit(message);
  assert.equal(h.listeners.size, 1);
  assert.equal(h.initializations, 1);
  assert.equal(h.registrations, 1);
  assert.equal(h.toasts.length, 1);
  h.toasts[0].onAction();
  assert.equal(h.navigations[0][0], "tickets");
  assert.equal(
    h.navigations[0][1],
    routes.ROUTES.adminVendorRegistration("42"),
  );
  h.stop();
});

test("duplicate delivery is suppressed while a genuinely new message remains visible", async () => {
  const h = harness();
  h.render();
  await tick();
  h.emit(message);
  h.emit(message);
  h.emit({ data });
  h.emit({ data });
  h.emit({ ...message, messageId: "message-2" });
  h.emit({ data: { ...data, registration_id: "invalid" } });
  assert.equal(h.toasts.length, 3);
  h.stop();
});

test("setup failures show once rather than repeating on each route", async () => {
  const h = harness(true);
  h.render();
  await tick();
  h.setNavigation(() => {});
  h.render({ ...options, user: { ...options.user } });
  await tick();
  assert.equal(h.toasts.length, 1);
  assert.equal(h.toasts[0].variant, "warning");
  assert.equal(h.initializations, 1);
  h.stop();
});

test("logout clears duplicate tracking and blocks old listeners and toast actions", async () => {
  const h = harness();
  h.render();
  await tick();
  const old = [...h.listeners][0];
  h.emit(message);
  h.render({ user: null, isAuthReady: true, isAuthenticated: false });
  await h.logout();
  old(message);
  h.toasts[0].onAction();
  assert.equal(h.toasts.length, 1);
  assert.equal(h.navigations.length, 0);
  assert.equal(h.logoutCalls, 1);
  h.render();
  await tick();
  h.emit(message);
  assert.equal(h.toasts.length, 2);
  h.stop();
});

test("different users have separate duplicate tracking and old listeners cannot deliver", async () => {
  const h = harness();
  h.render();
  await tick();
  const old = [...h.listeners][0];
  h.emit(message);
  h.render({ ...options, user: { userId: 8, role: "AdminOfficer" } });
  await tick();
  old({ ...message, messageId: "old-session" });
  h.emit(message);
  assert.equal(h.listeners.size, 1);
  assert.equal(h.toasts.length, 2);
  h.stop();
});

test("Strict Mode initialization cleanup leaves one active listener", async () => {
  const h = harness();
  h.render();
  h.resetEffect();
  h.render();
  await tick();
  assert.equal(h.listeners.size, 1);
  assert.equal(h.initializations, 1);
  assert.equal(h.registrations, 1);
  h.stop();
  assert.equal(h.listeners.size, 0);
});

test("non-admin users cannot receive registration review toasts", async () => {
  for (const role of ["MarketEnforcer", "MarketVendor"]) {
    const h = harness();
    h.render({ ...options, user: { userId: 9, role } });
    await tick();
    h.emit(message);
    assert.equal(h.toasts.length, 0);
    h.stop();
  }
});

test("background delivery waits for the tab to become visible and is shown once", async () => {
  const h = harness();
  h.render();
  await tick();
  h.visibility("hidden");
  h.background(message);
  h.background(message);
  h.emit(message);
  assert.equal(h.toasts.length, 0);
  h.visibility("visible");
  assert.equal(h.toasts.length, 1);
  assert.equal(h.toasts[0].duration, 12000);
  h.toasts[0].onAction();
  assert.equal(h.navigations[0][1], "/admin/vendor-registrations/review/42");
  h.visibility("hidden");
  h.visibility("visible");
  h.background(message);
  assert.equal(h.toasts.length, 1);
  h.stop();
  assert.equal(h.workerListeners.size, 0);
  assert.equal(h.visibilityListeners.size, 0);
});

test("foreground messages received while hidden are queued until return", async () => {
  const h = harness();
  h.render();
  await tick();
  h.visibility("hidden");
  h.emit(message);
  h.emit({ ...message, messageId: "message-2" });
  assert.equal(h.toasts.length, 0);
  h.visibility("visible");
  assert.equal(h.toasts.length, 2);
  h.stop();
});

test("logout discards queued messages and other roles cannot receive worker messages", async () => {
  const h = harness();
  h.render();
  await tick();
  h.visibility("hidden");
  h.background(message);
  h.render({ user: null, isAuthenticated: false, isAuthReady: true });
  await h.logout();
  h.visibility("visible");
  assert.equal(h.toasts.length, 0);
  for (const role of ["MarketEnforcer", "MarketVendor"]) {
    h.render({ ...options, user: { userId: 9, role } });
    await tick();
    h.background(message);
    assert.equal(h.toasts.length, 0);
  }
  h.stop();
});

test("worker handoff rejects unrelated sources and malformed payloads", async () => {
  const h = harness();
  h.render();
  await tick();
  h.background(message, "https://other.test/firebase-messaging-sw.js");
  h.background(message, "https://example.test/other-worker.js");
  for (const payload of [
    null,
    {},
    { data: null },
    { data: { ...data, registration_id: {} } },
    { data: { ...data, registration_id: "42/invalid" } },
    { data: { ...data, type: "other" } },
  ]) {
    h.background(payload);
  }
  assert.equal(h.toasts.length, 0);
  h.background(message);
  assert.equal(h.toasts.length, 1);
  h.stop();
});

function workerHarness() {
  let receive;
  const posts = [],
    notifications = [];
  vm.runInNewContext(
    fs.readFileSync(
      new URL("../../../public/firebase-messaging-sw.js", import.meta.url),
      "utf8",
    ),
    {
      URL,
      importScripts: () => {},
      firebase: {
        initializeApp: () => {},
        messaging: () => ({
          onBackgroundMessage: (callback) => {
            receive = callback;
          },
        }),
      },
      self: {
        location: {
          origin: "https://example.test",
          href: "https://example.test/firebase-messaging-sw.js?apiKey=test&authDomain=test&projectId=test&messagingSenderId=test&appId=test",
        },
        addEventListener: () => {},
        clients: {
          matchAll: async () => [
            {
              url: "https://example.test/dashboard",
              postMessage: (value) => posts.push(value),
            },
            {
              url: "https://other.test/",
              postMessage: () => assert.fail("Cross-origin handoff"),
            },
          ],
        },
        registration: {
          showNotification: async (...args) => notifications.push(args),
        },
      },
    },
  );
  return { receive: (payload) => receive(payload), posts, notifications };
}

test("worker forwards notification payloads without creating a duplicate system alert", async () => {
  const h = workerHarness();
  await h.receive({
    ...message,
    notification: { title: "New vendor registration request" },
  });
  assert.equal(h.posts.length, 1);
  assert.equal(h.posts[0].type, "vendor-registration-push");
  assert.equal(h.posts[0].payload.data.registration_id, "42");
  assert.equal(h.posts[0].payload.messageId, "message-1");
  assert.equal(h.notifications.length, 0);
});

test("worker keeps data-only push alerts and rejects invalid registration messages", async () => {
  const h = workerHarness();
  await h.receive(message);
  assert.equal(h.posts.length, 1);
  assert.equal(h.notifications.length, 1);
  await h.receive({ data: { ...data, registration_id: "invalid" } });
  await h.receive({ data: { ...data, type: "other" } });
  assert.equal(h.posts.length, 1);
  assert.equal(h.notifications.length, 1);
});
