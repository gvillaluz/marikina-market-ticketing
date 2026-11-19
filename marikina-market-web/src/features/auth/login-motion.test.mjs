import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";
import test from "node:test";
import vm from "node:vm";
import React from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { StaticRouter } from "react-router-dom/server.js";
import ts from "typescript";

const require = createRequire(import.meta.url);
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");

function load(relative, overrides = {}, globals = {}, cache = new Map()) {
  const file = path.resolve(root, relative);
  if (cache.has(file)) return cache.get(file);
  const module = { exports: {} };
  cache.set(file, module.exports);
  const code = ts.transpileModule(fs.readFileSync(file, "utf8"), {
    compilerOptions: {
      module: ts.ModuleKind.CommonJS,
      target: ts.ScriptTarget.ES2022,
      jsx: ts.JsxEmit.ReactJSX,
      esModuleInterop: true,
    },
  }).outputText;
  vm.runInNewContext(
    code,
    {
      module,
      exports: module.exports,
      ...globals,
      require(id) {
        if (id in overrides) return { __esModule: true, ...overrides[id] };
        if (id.endsWith(".css"))
          return {
            __esModule: true,
            default: new Proxy({}, { get: (_, key) => key }),
          };
        if (!id.startsWith(".") && !id.startsWith("@/")) return require(id);
        const base = id.startsWith("@/")
          ? path.resolve(root, id.slice(2))
          : path.resolve(path.dirname(file), id);
        const resolved = [base, `${base}.ts`, `${base}.tsx`, `${base}/index.ts`].find(
          (candidate) => fs.existsSync(candidate) && fs.statSync(candidate).isFile(),
        );
        assert.ok(resolved, `Cannot resolve ${id}`);
        const alias = `@/${path
          .relative(root, resolved)
          .replaceAll("\\", "/")
          .replace(/\.tsx?$/, "")}`;
        if (alias in overrides) return { __esModule: true, ...overrides[alias] };
        return load(path.relative(root, resolved), overrides, globals, cache);
      },
    },
    { filename: file },
  );
  return module.exports;
}

const render = (element) =>
  renderToStaticMarkup(React.createElement(StaticRouter, null, element));
const noop = () => {};
const tick = () => new Promise((resolve) => setImmediate(resolve));
function deferred() {
  let resolve;
  const promise = new Promise((done) => (resolve = done));
  return { promise, resolve };
}
const seal = {
  "@/assets/icons/Marikina_City_Seal.svg (1).webp": { default: "seal.webp" },
};

// A tiny stand-in for React's state: hooks are called again to "re-render".
function reactHarness() {
  const slots = [];
  const ran = [];
  let cursor = 0;
  return {
    react: {
      useState(initial) {
        const i = cursor++;
        if (!(i in slots))
          slots[i] = { v: typeof initial === "function" ? initial() : initial };
        const slot = slots[i];
        return [
          slot.v,
          (next) => {
            slot.v = typeof next === "function" ? next(slot.v) : next;
          },
        ];
      },
      useRef(initial) {
        const i = cursor++;
        if (!(i in slots)) slots[i] = { current: initial };
        return slots[i];
      },
      useEffect(effect) {
        const i = cursor++;
        if (!ran[i]) {
          ran[i] = true;
          effect();
        }
      },
    },
    render(hook) {
      cursor = 0;
      return hook();
    },
  };
}

// ---------------------------------------------------------------------------
// Pure helpers
// ---------------------------------------------------------------------------

test("the success pause lasts 0.4 s, and does not wait at all when motion is turned off", async () => {
  const waits = [];
  const motion = (reduced) =>
    load(
      "features/auth/motion.ts",
      {},
      {
        window: {
          matchMedia: () => ({ matches: reduced }),
          setTimeout: (callback, ms) => {
            waits.push(ms);
            callback();
            return 0;
          },
        },
      },
    );
  await motion(false).successPause();
  assert.deepEqual(waits, [400]);
  waits.length = 0;
  await motion(true).successPause();
  assert.deepEqual(waits, []);
});

test("the resend ring fill is the share of the waiting time already gone", () => {
  const { cooldownProgress } = load("features/auth/motion.ts");
  assert.equal(cooldownProgress(60, 60), 0);
  assert.equal(cooldownProgress(45, 60), 0.25);
  assert.equal(cooldownProgress(30, 60), 0.5);
  assert.equal(cooldownProgress(0, 60), 1);
  assert.equal(cooldownProgress(0, 0), 1);
  assert.equal(cooldownProgress(70, 60), 0);
});

test("the ring starts empty for each new waiting time and is full when it ends", () => {
  const h = reactHarness();
  const { useCooldownProgress } = load("features/auth/hooks/useCooldownProgress.ts", {
    react: h.react,
  });
  const run = (remaining) => h.render(() => useCooldownProgress(remaining));
  assert.equal(run(60), 0);
  assert.equal(run(45), 0.25);
  assert.equal(run(30), 0.5);
  assert.equal(run(0), 1);
  assert.equal(run(20), 0);
  assert.equal(run(10), 0.5);
});

test("a message keeps its words while it closes, and re-announces when it opens again", () => {
  const h = reactHarness();
  const { useHeldMessage } = load("features/auth/hooks/useHeldMessage.ts", {
    react: h.react,
  });
  const run = (message) => h.render(() => useHeldMessage(message));
  let view = run("Invalid username or password.");
  assert.equal(view.text, "Invalid username or password.");
  assert.equal(view.open, true);
  const firstKey = view.openKey;
  view = run("Invalid username or password.");
  assert.equal(view.openKey, firstKey);
  view = run("");
  assert.equal(view.text, "Invalid username or password.");
  assert.equal(view.open, false);
  view = run("Invalid username or password.");
  assert.equal(view.open, true);
  assert.notEqual(view.openKey, firstKey);
  view = run("User not found.");
  assert.equal(view.text, "User not found.");
});

// ---------------------------------------------------------------------------
// Small components
// ---------------------------------------------------------------------------

test("a message block is open with its words, or closed and empty", () => {
  const { default: RevealMessage } = load("features/auth/components/RevealMessage.tsx");
  const open = render(
    React.createElement(RevealMessage, {
      message: "Wrong code.",
      className: "err",
      role: "alert",
      id: "code-error",
    }),
  );
  assert.match(open, /data-open="true"/);
  assert.match(open, /<p[^>]*id="code-error"[^>]*role="alert"[^>]*>Wrong code\.<\/p>/);
  const closed = render(React.createElement(RevealMessage, { message: "", className: "err" }));
  assert.match(closed, /data-open="false"/);
  assert.doesNotMatch(closed, /<p/);
});

test("the submit button shows its words, a waiting state or a tick", () => {
  const { default: AuthSubmitButton } = load("features/auth/components/AuthSubmitButton.tsx");
  const button = (props) =>
    render(
      React.createElement(AuthSubmitButton, {
        label: "Verify and log in",
        busyLabel: "Verifying…",
        busy: false,
        done: false,
        className: "mine",
        ...props,
      }),
    );
  const idle = button({});
  assert.match(idle, /<button[^>]*data-state="idle"/);
  assert.match(idle, /Verify and log in/);
  assert.doesNotMatch(idle, /disabled/);
  const busy = button({ busy: true });
  assert.match(busy, /data-state="busy"/);
  assert.match(busy, /Verifying…/);
  assert.doesNotMatch(busy, /Verify and log in/);
  assert.match(busy, /disabled/);
  const done = button({ busy: true, done: true });
  assert.match(done, /data-state="done"/);
  assert.match(done, /aria-label="Done"/);
  assert.match(done, /<svg/);
  assert.doesNotMatch(done, /Verifying…|Verify and log in/);
  assert.match(button({ disabled: true }), /disabled/);
});

test("the resend ring is filled in proportion to the progress", () => {
  const { default: ResendRing } = load("features/auth/components/ResendRing.tsx");
  assert.match(render(React.createElement(ResendRing, { progress: 0.5 })), /stroke-dashoffset="50"/);
  assert.match(render(React.createElement(ResendRing, { progress: 0 })), /stroke-dashoffset="100"/);
  assert.match(render(React.createElement(ResendRing, { progress: 1 })), /stroke-dashoffset="0"/);
});

test("the code boxes mark a wrong code and a right code on the row", () => {
  const { default: OtpCodeInput } = load("features/auth/components/OtpCodeInput.tsx");
  const model = {
    code: ["1", "2", "3", "4", "5", "6"],
    changeCode: noop,
    setInputRef: noop,
    pasteCode: noop,
    keyDown: noop,
  };
  const row = (invalid, success) =>
    render(
      React.createElement(OtpCodeInput, {
        model,
        disabled: false,
        invalid,
        success,
        descriptionId: "d",
      }),
    );
  assert.doesNotMatch(row(false, false), /data-invalid|data-success/);
  assert.match(row(true, false), /data-invalid="true"/);
  assert.match(row(false, true), /data-success="true"/);
  assert.equal(row(false, false).match(/<input/g).length, 6);
});

// ---------------------------------------------------------------------------
// The success pause in each hook
// ---------------------------------------------------------------------------

const ROUTES = {
  adminLogin: "/admin/login",
  loginVerification: "/auth/verify-login",
  changePassword: "/admin/change-password",
  dashboard: "/dashboard",
};
const realMotion = load("features/auth/motion.ts");
const errorText = {
  getApiErrorMessage: (error, fallback) => error?.message ?? fallback,
  isConnectionError: () => false,
};

test("code page: the tick shows first, the next page opens after the pause, and the page keeps its details meanwhile", async () => {
  const h = reactHarness();
  const pause = deferred();
  const navigated = [];
  const challenge = {
    maskedEmail: "a***@example.invalid",
    expiresAt: Date.now() + 60000,
    resendAvailableAt: Date.now() + 30000,
  };
  let auth = {
    loginChallenge: challenge,
    verifyLogin: async () => ({ user: { role: "HeadAdmin" }, mustChangePassword: false }),
    resendLogin: noop,
    cancelLogin: noop,
    isAuthenticated: false,
    user: null,
    mustChangePassword: false,
  };
  const { useTwoFactorLogin } = load(
    "features/auth/hooks/useTwoFactorLogin.ts",
    {
      react: h.react,
      "react-router-dom": {
        useLocation: () => ({ state: {} }),
        useNavigate: () => (to) => navigated.push(to),
      },
      "@/context/AuthContext": { useAuth: () => auth },
      "@/api/types/common.types": { STAFF_ROLES: ["HeadAdmin"] },
      "@/routes/routePaths": { ROUTES },
      "@/utils/roles": { roleHomePath: () => ROUTES.dashboard },
      "@/utils/apiErrors": errorText,
      "../motion": { successPause: () => pause.promise, cooldownProgress: () => 0 },
      "./useCooldownProgress": { useCooldownProgress: () => 0 },
      "./useOtpInput": {
        useOtpInput: () => ({ code: ["1", "2", "3", "4", "5", "6"], reset: noop, focusFirst: noop }),
      },
    },
    { window: { setInterval: () => 0, clearInterval: noop } },
  );
  const view = () => h.render(useTwoFactorLogin);
  const done = view().verify({ preventDefault: noop });
  await tick();
  let model = view();
  assert.equal(model.succeeded, true);
  assert.equal(model.verifying, true);
  assert.deepEqual(navigated, []);
  auth = { ...auth, loginChallenge: null, isAuthenticated: true, user: { role: "HeadAdmin" } };
  model = view();
  assert.equal(model.maskedEmail, "a***@example.invalid");
  assert.equal(model.expired, false);
  pause.resolve();
  await done;
  assert.deepEqual(navigated, [ROUTES.dashboard]);
});

test("code page: a wrong code sets the error, shows no tick, and clears the error when you try again", async () => {
  const h = reactHarness();
  const navigated = [];
  const second = deferred();
  let attempts = 0;
  const auth = {
    loginChallenge: {
      maskedEmail: "a***@example.invalid",
      expiresAt: Date.now() + 60000,
      resendAvailableAt: Date.now() + 30000,
    },
    verifyLogin: async () => {
      attempts += 1;
      if (attempts === 1) throw new Error("The code is incorrect.");
      return second.promise;
    },
    resendLogin: noop,
    cancelLogin: noop,
    isAuthenticated: false,
    user: null,
    mustChangePassword: false,
  };
  const { useTwoFactorLogin } = load(
    "features/auth/hooks/useTwoFactorLogin.ts",
    {
      react: h.react,
      "react-router-dom": {
        useLocation: () => ({ state: {} }),
        useNavigate: () => (to) => navigated.push(to),
      },
      "@/context/AuthContext": { useAuth: () => auth },
      "@/api/types/common.types": { STAFF_ROLES: ["HeadAdmin"] },
      "@/routes/routePaths": { ROUTES },
      "@/utils/roles": { roleHomePath: () => ROUTES.dashboard },
      "@/utils/apiErrors": errorText,
      "../motion": { successPause: async () => {}, cooldownProgress: () => 0 },
      "./useCooldownProgress": { useCooldownProgress: () => 0 },
      "./useOtpInput": {
        useOtpInput: () => ({ code: ["1", "2", "3", "4", "5", "6"], reset: noop, focusFirst: noop }),
      },
    },
    { window: { setInterval: () => 0, clearInterval: noop } },
  );
  const view = () => h.render(useTwoFactorLogin);
  await view().verify({ preventDefault: noop });
  let model = view();
  assert.equal(model.error, "The code is incorrect.");
  assert.equal(model.succeeded, false);
  assert.equal(model.verifying, false);
  view().verify({ preventDefault: noop });
  assert.equal(view().error, "");
  assert.deepEqual(navigated, []);
});

test("forgot-password code step: tick first, then the next step; the ring starts empty", async () => {
  const h = reactHarness();
  const pause = deferred();
  const verified = [];
  const { useRecoveryVerification } = load(
    "features/auth/hooks/useRecoveryVerification.ts",
    {
      react: h.react,
      "@/api/endpoints/auth.api": {
        authApi: {
          sendCode: async () => ({ resendCooldownSeconds: 60 }),
          verifyCode: async () => ({ success: true, resetToken: "token-1" }),
        },
      },
      "@/utils/apiErrors": errorText,
      "../motion": { ...realMotion, successPause: () => pause.promise },
    },
  );
  const view = () =>
    h.render(() => useRecoveryVerification("ADM1-2026", "email", (token) => verified.push(token)));
  view();
  await tick();
  assert.equal(view().sent, true);
  assert.equal(view().resendProgress, 0);
  view().changeCode(0, "123456");
  const done = view().verify({ preventDefault: noop });
  await tick();
  const model = view();
  assert.equal(model.succeeded, true);
  assert.equal(model.verifying, true);
  assert.deepEqual(verified, []);
  pause.resolve();
  await done;
  assert.deepEqual(verified, ["token-1"]);
});

test("forgot-password code step: a wrong code gives no tick", async () => {
  const h = reactHarness();
  const verified = [];
  const { useRecoveryVerification } = load(
    "features/auth/hooks/useRecoveryVerification.ts",
    {
      react: h.react,
      "@/api/endpoints/auth.api": {
        authApi: {
          sendCode: async () => ({ resendCooldownSeconds: 60 }),
          verifyCode: async () => ({ success: false, message: "The verification code is invalid." }),
        },
      },
      "@/utils/apiErrors": errorText,
      "../motion": { ...realMotion, successPause: async () => {} },
    },
  );
  const view = () =>
    h.render(() => useRecoveryVerification("ADM1-2026", "email", (token) => verified.push(token)));
  view();
  await tick();
  view().changeCode(0, "123456");
  await view().verify({ preventDefault: noop });
  const model = view();
  assert.equal(model.error, "The verification code is invalid.");
  assert.equal(model.succeeded, false);
  assert.deepEqual(verified, []);
  view().changeCode(5, "9");
  assert.equal(view().error, "");
});

test("log in: the tick shows first and the code page opens after the pause", async () => {
  const h = reactHarness();
  const pause = deferred();
  const navigated = [];
  const { useLogin } = load("features/auth/hooks/useLogin.ts", {
    react: h.react,
    "react-router-dom": {
      useNavigate: () => (to) => navigated.push(to),
      useLocation: () => ({ state: null }),
    },
    "@/context/AuthContext": { useAuth: () => ({ login: async () => ({}), cancelLogin: noop }) },
    "@/routes/routePaths": { ROUTES },
    "@/utils/apiErrors": errorText,
    "../motion": { successPause: () => pause.promise },
  });
  const view = () => h.render(() => useLogin());
  const done = view().submit({ username: "ADM1-2026", password: "Abcdefg1" });
  await tick();
  const model = view();
  assert.equal(model.succeeded, true);
  assert.equal(model.loading, true);
  assert.deepEqual(navigated, []);
  pause.resolve();
  await done;
  assert.deepEqual(navigated, [ROUTES.loginVerification]);
});

test("log in: a refused login gives no tick and no move", async () => {
  const h = reactHarness();
  const navigated = [];
  const { useLogin } = load("features/auth/hooks/useLogin.ts", {
    react: h.react,
    "react-router-dom": {
      useNavigate: () => (to) => navigated.push(to),
      useLocation: () => ({ state: null }),
    },
    "@/context/AuthContext": {
      useAuth: () => ({
        login: async () => {
          throw new Error("Invalid username or password.");
        },
        cancelLogin: noop,
      }),
    },
    "@/routes/routePaths": { ROUTES },
    "@/utils/apiErrors": errorText,
    "../motion": { successPause: async () => {} },
  });
  const view = () => h.render(() => useLogin());
  await view().submit({ username: "x", password: "y" });
  const model = view();
  assert.equal(model.error, "Invalid username or password.");
  assert.equal(model.succeeded, false);
  assert.deepEqual(navigated, []);
});

test("forgot-password step 4: tick first, then back to log in", async () => {
  const h = reactHarness();
  const pause = deferred();
  const completed = [];
  const { useRecoveryReset } = load("features/auth/hooks/useRecoveryReset.ts", {
    react: h.react,
    "@/api/endpoints/auth.api": {
      authApi: { resetPassword: async () => ({ success: true }) },
    },
    "@/features/profile": { newPasswordError: () => undefined },
    "@/utils/apiErrors": errorText,
    "../motion": { successPause: () => pause.promise },
  });
  const view = () =>
    h.render(() => useRecoveryReset("ADM1-2026", "token-1", () => completed.push("done")));
  view().changePassword("Abcdefg1");
  view().changeConfirmation("Abcdefg1");
  const finished = view().submit({ preventDefault: noop });
  await tick();
  const model = view();
  assert.equal(model.succeeded, true);
  assert.equal(model.loading, true);
  assert.deepEqual(completed, []);
  pause.resolve();
  await finished;
  assert.deepEqual(completed, ["done"]);
});

test("change password: the tick shows before the toast and the move back to log in", async () => {
  const h = reactHarness();
  const pause = deferred();
  const events = [];
  const { useMandatoryChangePassword } = load("features/auth/hooks/useMandatoryChangePassword.ts", {
    react: h.react,
    "@/context/AuthContext": { useAuth: () => ({ logout: () => events.push("logout") }) },
    "@/components/ui/Toast/useToast": {
      useToast: () => ({ showToast: () => events.push("toast") }),
    },
    "@/api/endpoints/auth.api": {
      authApi: { mandatoryChangePassword: async () => events.push("saved") },
    },
    "@/features/profile": { validatePasswordForm: () => ({}) },
    "@/utils/apiErrors": errorText,
    "../motion": { successPause: () => pause.promise },
  });
  const view = () => h.render(useMandatoryChangePassword);
  const finished = view().submit({ preventDefault: noop });
  await tick();
  const model = view();
  assert.equal(model.succeeded, true);
  assert.equal(model.loading, true);
  assert.deepEqual(events, ["saved"]);
  pause.resolve();
  await finished;
  assert.deepEqual(events, ["saved", "toast", "logout"]);
});

// ---------------------------------------------------------------------------
// The pages use the new pieces
// ---------------------------------------------------------------------------

const otpModel = {
  code: ["1", "2", "3", "", "", ""],
  changeCode: noop,
  setInputRef: noop,
  pasteCode: noop,
  keyDown: noop,
};

test("the login form opens its message, and shows the waiting and success states on the button", () => {
  const formModel = {
    username: "",
    password: "",
    showPassword: false,
    fieldErrors: {},
    passwordReset: false,
    usernameRef: null,
    passwordRef: null,
    changeUsername: noop,
    changePassword: noop,
    togglePassword: noop,
    forgotPassword: noop,
    handleSubmit: noop,
  };
  const { default: LoginForm } = load("features/auth/components/LoginForm.tsx", {
    "@/features/auth/hooks/useLoginForm": { useLoginForm: () => formModel },
    "@/features/auth/hooks/useCapsLock": {
      useCapsLock: () => ({ field: null, bind: () => ({}) }),
    },
  });
  const form = (props) =>
    render(
      React.createElement(LoginForm, {
        submit: async () => {},
        loading: false,
        succeeded: false,
        error: null,
        ...props,
      }),
    );
  const quiet = form({});
  assert.match(quiet, /data-state="idle"/);
  assert.match(quiet, />Log in<\/span><\/button>/);
  assert.match(quiet, /data-open="false"/);
  assert.doesNotMatch(quiet, /Invalid username or password\./);
  const failed = form({ error: "Invalid username or password." });
  assert.match(failed, /data-open="true"[^]*role="alert"[^>]*>Invalid username or password\./);
  assert.match(form({ loading: true }), /data-state="busy"[^]*Sending code…/);
  assert.match(form({ loading: true, succeeded: true }), /data-state="done"/);
});

function codePage(model = {}, props = {}) {
  const { default: LoginVerificationPage } = load("features/auth/pages/LoginVerificationPage.tsx", {
    ...seal,
    "@/features/auth/hooks/useTwoFactorLogin": {
      useTwoFactorLogin: () => ({
        isAuthenticated: false,
        loginChallenge: { maskedEmail: "a***@example.invalid" },
        maskedEmail: "a***@example.invalid",
        cancel: noop,
        verify: noop,
        resend: noop,
        verifying: false,
        resending: false,
        succeeded: false,
        canVerify: true,
        canResend: false,
        resendLabel: "Resend in 00:26",
        cooldownSeconds: 26,
        resendProgress: 0.5,
        expired: false,
        notice: "",
        error: "",
        otp: otpModel,
        ...model,
      }),
    },
    ...props,
  });
  return render(React.createElement(LoginVerificationPage));
}

test("code page: ring while waiting, none when resend is ready, boxes and button follow the result", () => {
  const waiting = codePage();
  assert.match(waiting, /stroke-dashoffset="50"/);
  assert.doesNotMatch(codePage({ cooldownSeconds: 0, resendProgress: 1, resendLabel: "Resend code" }), /<svg[^>]*stroke-dashoffset/);
  assert.match(codePage({ error: "The code is incorrect." }), /data-invalid="true"/);
  const right = codePage({ succeeded: true, verifying: true, loginChallenge: null, isAuthenticated: true });
  assert.match(right, /data-success="true"/);
  assert.match(right, /data-state="done"/);
  assert.match(right, /a\*\*\*@example\.invalid/);
});

test("code page: while the tick shows, the page does not jump away early", () => {
  const holding = { verifying: true, succeeded: true, loginChallenge: null, isAuthenticated: true };
  assert.match(codePage(holding), /Verify and log in|data-state="done"/);
  assert.equal(codePage({ ...holding, verifying: false, succeeded: false }), "");
});

test("forgot-password code step: the same ring, boxes and button", () => {
  const verification = (model = {}) => ({
    code: otpModel.code,
    sending: false,
    resending: false,
    verifying: false,
    succeeded: false,
    error: "",
    notice: "",
    sent: true,
    busy: false,
    cooldown: 26,
    cooldownLabel: "00:26",
    resendProgress: 0.5,
    canResend: false,
    canVerify: true,
    setInputRef: noop,
    changeCode: noop,
    pasteCode: noop,
    keyDown: noop,
    resend: noop,
    verify: noop,
    ...model,
  });
  const page = (model) => {
    const { default: VerifyCodePage } = load(
      "features/auth/components/recovery/VerifyCodePage.tsx",
      {
        "@/features/auth/hooks/useRecoveryVerification": {
          useRecoveryVerification: () => verification(model),
        },
      },
    );
    return render(
      React.createElement(VerifyCodePage, {
        username: "ADM1-2026",
        channel: "email",
        maskedEmail: "a***@example.invalid",
        onVerified: noop,
      }),
    );
  };
  assert.match(page(), /stroke-dashoffset="50"/);
  assert.doesNotMatch(page({ cooldown: 0, resendProgress: 1 }), /stroke-dashoffset/);
  assert.match(page({ error: "The verification code is invalid." }), /data-invalid="true"/);
  const right = page({ succeeded: true, verifying: true, busy: true, canVerify: false });
  assert.match(right, /data-success="true"/);
  assert.match(right, /data-state="done"/);
  assert.match(page(), /data-state="idle"[^]*>Verify<\/span>/);
});

test("change password and step 4 buttons show the waiting words and the tick", () => {
  const { default: ChangePasswordPage } = load("features/auth/pages/ChangePasswordPage.tsx", {
    ...seal,
    "@/features/auth/hooks/useCapsLock": {
      useCapsLock: () => ({ field: null, bind: () => ({}) }),
    },
    "@/features/auth/hooks/useMandatoryChangePassword": {
      useMandatoryChangePassword: () => ({
        backToSignIn: noop,
        submit: async () => null,
        change: noop,
        toggleShown: noop,
        loading: true,
        succeeded: true,
        error: "",
        fieldErrors: {},
        shown: {},
        values: { currentPassword: "", newPassword: "", confirmNewPassword: "" },
      }),
    },
  });
  const html = render(React.createElement(ChangePasswordPage));
  assert.match(html, /data-state="done"/);
  assert.match(html, /data-open="false"/);
  const { default: ResetPasswordPage } = load(
    "features/auth/components/recovery/ResetPasswordPage.tsx",
    {
      "@/features/auth/hooks/useCapsLock": {
        useCapsLock: () => ({ field: null, bind: () => ({}) }),
      },
      "@/features/auth/hooks/useRecoveryReset": {
        useRecoveryReset: () => ({
          newPassword: "Abcdefg1",
          confirmPassword: "Abcdefg1",
          showNewPassword: false,
          showConfirmPassword: false,
          loading: true,
          succeeded: false,
          error: "",
          mismatch: false,
          changePassword: noop,
          changeConfirmation: noop,
          togglePassword: noop,
          toggleConfirmation: noop,
          submit: noop,
        }),
      },
    },
  );
  const reset = render(
    React.createElement(ResetPasswordPage, { username: "u", resetToken: "t", onComplete: noop }),
  );
  assert.match(reset, /data-state="busy"[^]*Changing password\.\.\./);
});

test("the find-your-account Continue button has the press feel but no waiting or tick", () => {
  const { default: AccountLookupPage } = load(
    "features/auth/components/recovery/AccountLookupPage.tsx",
    {
      "@/features/auth/hooks/useRecoveryLookup": {
        useRecoveryLookup: () => ({
          username: "",
          error: "Enter your username.",
          changeUsername: noop,
          submit: noop,
        }),
      },
    },
  );
  const html = render(
    React.createElement(AccountLookupPage, {
      initialUsername: "",
      initialError: "",
      onContinue: noop,
    }),
  );
  assert.match(html, /data-state="idle"[^]*>Continue<\/span>/);
  assert.match(html, /data-open="true"[^]*Enter your username\./);
});

test("log in: when the server cannot be reached, it says there is no connection", async () => {
  const apiErrors = load("utils/apiErrors.ts");
  const loginWith = (h, error) =>
    load("features/auth/hooks/useLogin.ts", {
      react: h.react,
      "react-router-dom": {
        useNavigate: () => noop,
        useLocation: () => ({ state: null }),
      },
      "@/context/AuthContext": {
        useAuth: () => ({
          login: async () => {
            throw error;
          },
          cancelLogin: noop,
        }),
      },
      "@/routes/routePaths": { ROUTES },
      "@/utils/apiErrors": apiErrors,
      "../motion": { successPause: async () => {} },
    }).useLogin;
  const errorAfterLogin = async (error) => {
    const h = reactHarness();
    const useLogin = loginWith(h, error);
    const view = () => h.render(() => useLogin());
    await view().submit({ username: "x", password: "y" });
    return view().error;
  };
  // No answer at all from the server: the request never arrived.
  assert.equal(
    await errorAfterLogin(new apiErrors.ApiRequestError()),
    "No internet connection. Please try again.",
  );
  // The server answered with an error and no message: keep the general one.
  assert.equal(
    await errorAfterLogin(new apiErrors.ApiRequestError(undefined, 500)),
    "Login failed.",
  );
});
