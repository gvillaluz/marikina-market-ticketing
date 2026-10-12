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
    URL,
    Error,
    FormData,
    ...globals,
    require: (id) => {
      assert.ok(id in mocks, id);
      return { __esModule: true, ...mocks[id] };
    },
  });
  return module.exports;
}

const photo = new File(["photo"], "photo.png", { type: "image/png" });
const response = {
  userId: 42,
  role: "MarketEnforcer",
  profileUrl: "https://storage.example.com/profile.png?signed=example",
};
const tick = () => new Promise((resolve) => setImmediate(resolve));

function harness() {
  let user = { userId: 42, profileUrl: "https://storage.example.com/old.png" },
    authenticated = true;
  const watchers = new Set(),
    states = [],
    refs = [],
    toasts = [],
    cached = [];
  let stateCursor = 0,
    refCursor = 0,
    cleanup,
    effectMounted = false,
    request,
    validation = null;
  let uploadCalls = 0,
    cancelCalls = 0,
    validateResponse = () => {};
  const store = {
    getState: () => ({
      user,
      isAuthenticated: authenticated,
      setUser: (value) => {
        user = value;
      },
    }),
    subscribe: (callback) => {
      watchers.add(callback);
      return () => watchers.delete(callback);
    },
  };
  class ApiRequestError extends Error {
    constructor(message) {
      super(message);
      this.serverMessage = message;
    }
  }
  const hook = load("./hooks/useProfilePhoto.ts", {
    react: {
      useId: () => "photo-input",
      useRef: (initial) => {
        const i = refCursor++;
        return (refs[i] ??= { current: initial });
      },
      useState: (initial) => {
        const i = stateCursor++;
        if (!(i in states)) states[i] = initial;
        return [
          states[i],
          (value) => {
            states[i] = value;
          },
        ];
      },
      useEffect: (effect) => {
        if (!effectMounted) {
          effectMounted = true;
          cleanup = effect();
        }
      },
    },
    "@tanstack/react-query": {
      useQueryClient: () => ({
        cancelQueries: async () => {
          cancelCalls++;
        },
        setQueryData: (key, value) => cached.push([key, value]),
      }),
    },
    "@/api/endpoints/profile.api": {
      profileApi: {
        changePhoto: () => {
          uploadCalls++;
          return request ?? Promise.resolve(response);
        },
      },
    },
    "@/store/store": { useAuthStore: store },
    "@/components/ui/Toast/useToast": {
      useToast: () => ({ showToast: (toast) => toasts.push(toast) }),
    },
    "@/utils/apiErrors": {
      ApiRequestError,
      getApiErrorMessage: (error, fallback) => error?.serverMessage || fallback,
    },
    "@/utils/roles": {
      normalizeUserRole: (role) => {
        if (role !== "MarketEnforcer") throw Error();
        return role;
      },
    },
    "../profile.validation": { validateProfilePhoto: async () => validation },
    "./useProfile": { validateProfile: (value) => validateResponse(value) },
  }).useProfilePhoto;
  return {
    render(disabled = false) {
      stateCursor = 0;
      refCursor = 0;
      return hook(42, disabled);
    },
    setRequest(value) {
      request = value;
    },
    setValidation(value) {
      validation = value;
    },
    logoutAndLoginSameUser() {
      const previous = store.getState();
      authenticated = false;
      user = null;
      for (const w of watchers) w(store.getState(), previous);
      const loggedOut = store.getState();
      authenticated = true;
      user = { userId: 42, profileUrl: "https://storage.example.com/old.png" };
      for (const w of watchers) w(store.getState(), loggedOut);
    },
    unmount() {
      cleanup?.();
    },
    get user() {
      return user;
    },
    get watchers() {
      return watchers.size;
    },
    get uploadCalls() {
      return uploadCalls;
    },
    get cancelCalls() {
      return cancelCalls;
    },
    cached,
    toasts,
    ApiRequestError,
  };
}

test("API sends the selected file as multipart file without forcing a JSON header", async () => {
  let request;
  const api = load("../../api/endpoints/profile.api.ts", {
    "@/api/client": {
      default: {
        put: async (...args) => {
          request = args;
          return { data: response };
        },
      },
    },
  }).profileApi;
  assert.equal(await api.changePhoto(photo), response);
  assert.equal(request[0], "/User/change-photo");
  assert.ok(request[1] instanceof FormData);
  assert.deepEqual([...request[1].keys()], ["file"]);
  assert.equal(request[1].get("file").name, "photo.png");
  assert.equal(request[2].headers["Content-Type"], undefined);
});

test("success updates the profile cache and auth photo, then releases upload state", async () => {
  const h = harness();
  await h.render().upload(photo);
  assert.equal(h.user.profileUrl, response.profileUrl);
  assert.equal(h.cached.length, 1);
  assert.equal(h.cancelCalls, 1);
  assert.equal(h.cached[0][0][1], 42);
  assert.equal(h.render().isSaving, false);
  assert.equal(h.toasts[0].title, "Profile photo updated");
  assert.equal(h.watchers, 0);
});

test("cancelled selection and invalid files do not call the endpoint", async () => {
  const h = harness();
  await h.render().upload(null);
  assert.equal(h.uploadCalls, 0);
  h.setValidation("Choose a JPEG, PNG, or WebP image.");
  await h.render().upload(photo);
  assert.equal(h.uploadCalls, 0);
  assert.match(h.render().error, /JPEG/);
  assert.equal(h.watchers, 0);
});

test("an in-flight upload blocks duplicates and resets the file input for retries", async () => {
  const h = harness();
  let resolve;
  h.setRequest(
    new Promise((r) => {
      resolve = r;
    }),
  );
  const first = h.render().upload(photo);
  await tick();
  await h.render().upload(photo);
  assert.equal(h.uploadCalls, 1);
  assert.equal(h.render().disabled, true);
  const target = { files: [photo], value: "photo.png" };
  h.render().selectPhoto({ currentTarget: target });
  assert.equal(target.value, "");
  assert.equal(h.uploadCalls, 1);
  resolve(response);
  await first;
  assert.equal(h.render().disabled, false);
});

test("API errors retain the old photo and display the server message", async () => {
  const h = harness();
  h.setRequest(
    Promise.reject(new h.ApiRequestError("The image is too large.")),
  );
  await h.render().upload(photo);
  assert.match(h.render().error, /too large/);
  assert.ok(h.user.profileUrl.includes("old"));
  assert.equal(h.cached.length, 0);
  assert.equal(h.toasts.length, 0);
});

test("logout followed by same-user login cannot accept an old upload response", async () => {
  const h = harness();
  let resolve;
  h.setRequest(
    new Promise((r) => {
      resolve = r;
    }),
  );
  const upload = h.render().upload(photo);
  await tick();
  h.logoutAndLoginSameUser();
  resolve(response);
  await upload;
  assert.equal(h.cached.length, 0);
  assert.equal(h.toasts.length, 0);
  assert.ok(h.user.profileUrl.includes("old"));
  assert.equal(h.watchers, 0);
});

test("response identity and photo URL must match the expected account and image source", async () => {
  for (const value of [
    { ...response, userId: 99 },
    { ...response, profileUrl: null },
    { ...response, profileUrl: "javascript:alert(1)" },
  ]) {
    const h = harness();
    h.setRequest(Promise.resolve(value));
    await h.render().upload(photo);
    assert.equal(h.cached.length, 0);
    assert.ok(h.render().error);
    assert.ok(h.user.profileUrl.includes("old"));
  }
});

test("leaving the page still updates the signed-in user's sidebar when the upload finishes", async () => {
  const h = harness();
  let resolve;
  h.setRequest(
    new Promise((r) => {
      resolve = r;
    }),
  );
  const upload = h.render().upload(photo);
  await tick();
  h.unmount();
  resolve(response);
  await upload;
  assert.equal(h.user.profileUrl, response.profileUrl);
  assert.equal(h.cached.length, 1);
  assert.equal(h.watchers, 0);
});

test("readability validation rejects corrupt images and always revokes the preview URL", async () => {
  for (const readable of [true, false]) {
    const revoked = [];
    const validator = load(
      "./profile.validation.ts",
      {},
      {
        URL: {
          createObjectURL: () => "blob:preview",
          revokeObjectURL: (url) => revoked.push(url),
        },
        Image: class {
          naturalWidth = 1;
          naturalHeight = 1;
          set src(_value) {
            queueMicrotask(() => (readable ? this.onload() : this.onerror()));
          }
        },
      },
    );
    const error = await validator.validateProfilePhoto(photo);
    assert.equal(error === null, readable);
    assert.deepEqual(revoked, ["blob:preview"]);
  }
  const validator = load("./profile.validation.ts");
  assert.match(
    await validator.validateProfilePhoto(
      new File([], "empty.png", { type: "image/png" }),
    ),
    /empty/,
  );
  assert.match(
    await validator.validateProfilePhoto(
      new File(["pdf"], "file.pdf", { type: "application/pdf" }),
    ),
    /JPEG/,
  );
});
