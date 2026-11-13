import assert from "node:assert/strict";
import fs from "node:fs";
import test from "node:test";
import vm from "node:vm";
import ts from "typescript";

function load(file, mocks) {
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
    require: (id) => {
      assert.ok(id in mocks, id);
      return { __esModule: true, ...mocks[id] };
    },
  });
  return module.exports;
}

const RULE = "Use at least 8 characters, with a number and a capital letter.";
const EXPIRED = "Your reset session has expired. Please start again.";

const { newPasswordError } = load("../profile/profile.validation.ts", {});
const { getApiErrorMessage } = load("../../utils/apiErrors.ts", {
  axios: { default: { isAxiosError: (error) => error?.isAxiosError === true } },
});

function harness(resetPassword) {
  const states = [];
  const refs = [];
  const calls = [];
  const completed = [];
  let stateCursor = 0;
  let refCursor = 0;
  const useRecoveryReset = load("./hooks/useRecoveryReset.ts", {
    react: {
      useState: (initial) => {
        const i = stateCursor++;
        if (!(i in states)) states[i] = initial;
        return [
          states[i],
          (value) => {
            states[i] = typeof value === "function" ? value(states[i]) : value;
          },
        ];
      },
      useRef: (initial) => {
        const i = refCursor++;
        return (refs[i] ??= { current: initial });
      },
      useEffect: (effect) => {
        effect();
      },
    },
    "@/api/endpoints/auth.api": {
      authApi: {
        resetPassword: async (input) => {
          calls.push(input);
          return resetPassword();
        },
      },
    },
    "@/utils/apiErrors": { getApiErrorMessage },
    "@/features/profile": { newPasswordError },
  }).useRecoveryReset;
  const render = () => {
    stateCursor = 0;
    refCursor = 0;
    return useRecoveryReset("ADM9005-2026", "token-123", () =>
      completed.push(true),
    );
  };
  const submit = async (password, confirmation = password) => {
    render().changePassword(password);
    render().changeConfirmation(confirmation);
    await render().submit({ preventDefault() {} });
    return render();
  };
  return { submit, calls, completed };
}

test("a password with no capital letter shows the rule and sends nothing", async () => {
  const h = harness(async () => ({ success: true, message: "ok" }));
  const view = await h.submit("abcdefg1");
  assert.equal(view.error, RULE);
  assert.equal(h.calls.length, 0);
  assert.equal(h.completed.length, 0);
});

test("a good password with a matching confirmation is sent", async () => {
  const h = harness(async () => ({ success: true, message: "ok" }));
  await h.submit("Abcdefg1");
  assert.deepEqual(JSON.parse(JSON.stringify(h.calls)), [
    {
      username: "ADM9005-2026",
      newPassword: "Abcdefg1",
      resetToken: "token-123",
    },
  ]);
});

test("a confirmation that differs shows the mismatch text and sends nothing", async () => {
  const h = harness(async () => ({ success: true, message: "ok" }));
  const view = await h.submit("Abcdefg1", "Abcdefg2");
  assert.equal(view.error, "Passwords do not match.");
  assert.equal(h.calls.length, 0);
});

test("success: true completes the reset", async () => {
  const h = harness(async () => ({ success: true, message: "ok" }));
  const view = await h.submit("Abcdefg1");
  assert.equal(h.completed.length, 1);
  assert.equal(view.error, "");
});

test("success: false shows the server message, does not complete, and stays on the page", async () => {
  const h = harness(async () => ({ success: false, message: EXPIRED }));
  const view = await h.submit("Abcdefg1");
  assert.equal(view.error, EXPIRED);
  assert.equal(h.completed.length, 0);
  assert.equal(view.loading, false);
});

test("success: false with no message shows the fallback", async () => {
  const h = harness(async () => ({ success: false, message: "" }));
  const view = await h.submit("Abcdefg1");
  assert.equal(view.error, "Could not reset your password. Please try again.");
  assert.equal(h.completed.length, 0);
});

test("a 400 from the server shows the rule text it sends", async () => {
  const h = harness(async () => {
    throw {
      isAxiosError: true,
      response: { status: 400, data: { errors: { NewPassword: [RULE] } } },
    };
  });
  const view = await h.submit("Abcdefg1");
  assert.equal(view.error, RULE);
  assert.equal(h.completed.length, 0);
});
