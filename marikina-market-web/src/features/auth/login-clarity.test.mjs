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

function load(relative, overrides = {}, cache = new Map()) {
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
        return load(path.relative(root, resolved), overrides, cache);
      },
    },
    { filename: file },
  );
  return module.exports;
}

const render = (element) =>
  renderToStaticMarkup(React.createElement(StaticRouter, null, element));
const noop = () => {};
const seal = {
  "@/assets/icons/Marikina_City_Seal.svg (1).webp": { default: "seal.webp" },
};

// ---------------------------------------------------------------------------
// B1. Password rules tick off as you type
// ---------------------------------------------------------------------------

test("each password rule is met on its own, and the error agrees with the rules", () => {
  const { PASSWORD_RULES, newPasswordError } = load(
    "features/profile/profile.validation.ts",
  );
  assert.deepEqual(
    Array.from(PASSWORD_RULES, (rule) => rule.label),
    ["At least 8 characters", "A number", "A capital letter"],
  );
  const met = (value) => Array.from(PASSWORD_RULES, (rule) => rule.met(value));
  assert.deepEqual(met(""), [false, false, false]);
  assert.deepEqual(met("abcdefgh"), [true, false, false]);
  assert.deepEqual(met("abc1"), [false, true, false]);
  assert.deepEqual(met("Abc"), [false, false, true]);
  assert.deepEqual(met("Abcdefg1"), [true, true, true]);
  assert.equal(newPasswordError("Abcdefg1"), undefined);
  assert.equal(
    newPasswordError("abcdefg1"),
    "Use at least 8 characters, with a number and a capital letter.",
  );
});

test("the checklist marks exactly the rules the typed password meets", () => {
  const { default: PasswordRuleChecklist } = load(
    "features/auth/components/PasswordRuleChecklist.tsx",
  );
  const html = render(
    React.createElement(PasswordRuleChecklist, { id: "rules", value: "abcdefg1" }),
  );
  assert.match(html, /<ul[^>]*id="rules"/);
  const items = [...html.matchAll(/<li[^>]*data-met="(true|false)"[^>]*>(.*?)<\/li>/g)].map(
    ([, met, inner]) => [inner.replace(/<[^>]+>/g, "").replace(/^(Done|Not yet): /, ""), met],
  );
  assert.deepEqual(items, [
    ["At least 8 characters", "true"],
    ["A number", "true"],
    ["A capital letter", "false"],
  ]);
});

function changePasswordPage(model = {}, capsField = null) {
  const { default: ChangePasswordPage } = load(
    "features/auth/pages/ChangePasswordPage.tsx",
    {
      ...seal,
      "@/features/auth/hooks/useCapsLock": {
        useCapsLock: () => ({ field: capsField, bind: () => ({}) }),
      },
      "@/features/auth/hooks/useMandatoryChangePassword": {
        useMandatoryChangePassword: () => ({
          backToSignIn: noop,
          submit: async () => null,
          change: noop,
          toggleShown: noop,
          loading: false,
          error: "",
          fieldErrors: {},
          shown: {},
          values: { currentPassword: "", newPassword: "Abc", confirmNewPassword: "" },
          ...model,
        }),
      },
    },
  );
  return render(React.createElement(ChangePasswordPage));
}

test("the change-password page shows the live checklist under the new password", () => {
  const html = changePasswordPage();
  assert.match(html, /<ul[^>]*id="mandatory-new-password-hint"/);
  assert.match(html, /data-met="false"[^>]*>.*At least 8 characters/);
  assert.match(html, /data-met="true"[^>]*>.*A capital letter/);
  assert.doesNotMatch(html, /At least 8 characters, with a number and a capital letter\./);
});

function resetStep(capsField = null) {
  const { default: ResetPasswordPage } = load(
    "features/auth/components/recovery/ResetPasswordPage.tsx",
    {
      "@/features/auth/hooks/useCapsLock": {
        useCapsLock: () => ({ field: capsField, bind: () => ({}) }),
      },
      "@/features/auth/hooks/useRecoveryReset": {
        useRecoveryReset: () => ({
          newPassword: "abcdefgh",
          confirmPassword: "",
          showNewPassword: false,
          showConfirmPassword: false,
          loading: false,
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
  return render(
    React.createElement(ResetPasswordPage, {
      username: "ADM9016-2026",
      resetToken: "token",
      onComplete: noop,
    }),
  );
}

test("forgot-password step 4 shows the live checklist instead of the rule sentence", () => {
  const html = resetStep();
  assert.match(html, /data-met="true"[^>]*>.*At least 8 characters/);
  assert.match(html, /data-met="false"[^>]*>.*A number/);
  assert.doesNotMatch(html, /At least 8 characters, with a number and a capital letter\./);
});

// ---------------------------------------------------------------------------
// B2. Caps Lock warning
// ---------------------------------------------------------------------------

function capsHarness() {
  const states = [];
  let cursor = 0;
  const { useCapsLock } = load("features/auth/hooks/useCapsLock.ts", {
    react: {
      useState: (initial) => {
        const i = cursor++;
        if (!(i in states)) states[i] = initial;
        return [states[i], (value) => (states[i] = value)];
      },
    },
  });
  return () => {
    cursor = 0;
    return useCapsLock();
  };
}
const key = (capsOn) => ({ getModifierState: (name) => name === "CapsLock" && capsOn });

test("the Caps Lock note follows the key and the box being typed in", () => {
  const run = capsHarness();
  assert.equal(run().field, null);
  run().bind("login-password").onKeyDown(key(true));
  assert.equal(run().field, "login-password");
  run().bind("login-password").onKeyUp(key(false));
  assert.equal(run().field, null);
  run().bind("confirm").onKeyUp(key(true));
  assert.equal(run().field, "confirm");
  run().bind("confirm").onBlur();
  assert.equal(run().field, null);
});

test("the login form shows the Caps Lock note under the password only while it is on", () => {
  const formModel = {
    username: "",
    password: "",
    showPassword: false,
    fieldErrors: {},
    usernameRef: null,
    passwordRef: null,
    changeUsername: noop,
    changePassword: noop,
    togglePassword: noop,
    forgotPassword: noop,
    handleSubmit: noop,
  };
  const loginForm = (capsField) =>
    load("features/auth/components/LoginForm.tsx", {
      "@/features/auth/hooks/useLoginForm": { useLoginForm: () => formModel },
      "@/features/auth/hooks/useCapsLock": {
        useCapsLock: () => ({ field: capsField, bind: () => ({}) }),
      },
    }).default;
  const props = { submit: async () => {}, loading: false, error: null };
  assert.doesNotMatch(
    render(React.createElement(loginForm(null), props)),
    /Caps Lock is on\./,
  );
  const html = render(React.createElement(loginForm("login-password"), props));
  assert.match(html, /Caps Lock is on\./);
  assert.ok(
    html.indexOf("Caps Lock is on.") > html.indexOf('id="login-password"'),
    "the note sits under the password box",
  );
});

test("the change-password and step 4 pages show the note only under the box in use", () => {
  const html = changePasswordPage({}, "mandatory-confirm-password");
  assert.equal(html.match(/Caps Lock is on\./g)?.length, 1);
  assert.ok(html.indexOf("Caps Lock is on.") > html.indexOf('id="mandatory-confirm-password"'));
  assert.doesNotMatch(changePasswordPage({}, null), /Caps Lock is on\./);
  assert.equal(resetStep("recovery-new-password").match(/Caps Lock is on\./g)?.length, 1);
});

// ---------------------------------------------------------------------------
// B4. "Log in" everywhere
// ---------------------------------------------------------------------------

test("the code page and change-password page say log in", () => {
  const { default: LoginVerificationPage } = load(
    "features/auth/pages/LoginVerificationPage.tsx",
    {
      ...seal,
      "@/features/auth/components/OtpCodeInput": { default: () => null },
      "@/features/auth/hooks/useTwoFactorLogin": {
        useTwoFactorLogin: () => ({
          isAuthenticated: false,
          loginChallenge: { maskedEmail: "a***@example.invalid" },
          cancel: noop,
          verify: noop,
          resend: noop,
          verifying: false,
          resending: false,
          canVerify: false,
          canResend: false,
          resendLabel: "Resend code",
          expired: false,
          notice: "",
          error: "",
          otp: {},
        }),
      },
    },
  );
  const code = render(React.createElement(LoginVerificationPage));
  assert.match(code, /Back to log in/);
  assert.match(code, />Verify and log in<\/span><\/button>/);
  assert.match(code, /to finish logging in\./);
  const change = changePasswordPage();
  assert.match(change, /Back to log in/);
  assert.match(change, />Save password<\/span><\/button>/);
  for (const html of [code, change]) {
    assert.doesNotMatch(html, /sign in|signing in/i);
    assert.doesNotMatch(html, /SAVE PASSWORD/);
  }
});

// The approved phrases: "Please sign in again", "Your sign-in session expired",
// "Sign-in was cancelled". The term "sign-in verification" (the code page's
// heading) was not part of the approved list and is left as it is.
test("no login-page message says sign in any more", () => {
  const files = [
    "features/auth/authSession.ts",
    "features/auth/hooks/useLogin.ts",
    "features/auth/hooks/useLoginChallenge.ts",
    "features/auth/hooks/useMandatoryChangePassword.ts",
    "features/profile/hooks/useChangePassword.ts",
    "utils/apiErrors.ts",
  ];
  for (const file of files) {
    const text = fs.readFileSync(path.resolve(root, file), "utf8");
    const strings = [...text.matchAll(/"([^"\n]*)"/g)].map(([, s]) => s);
    const said = strings.filter((s) =>
      /sign in|sign-in session|sign-in was/i.test(s),
    );
    assert.deepEqual(said, [], file);
  }
});
