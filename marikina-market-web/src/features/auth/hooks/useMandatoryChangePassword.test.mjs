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

const { validatePasswordForm } = load(
  "../../profile/profile.validation.ts",
  {},
);
const { getApiErrorMessage } = load("../../../utils/apiErrors.ts", {
  axios: { default: { isAxiosError: (error) => error?.isAxiosError === true } },
});

function harness(mandatoryChangePassword = async () => {}) {
  const states = [];
  const refs = [];
  const calls = [];
  const toasts = [];
  const events = [];
  let stateCursor = 0;
  let refCursor = 0;
  let lastResult;
  const { useMandatoryChangePassword } = load(
    "./useMandatoryChangePassword.ts",
    {
      react: {
        useState: (initial) => {
          const i = stateCursor++;
          if (!(i in states)) states[i] = initial;
          return [
            states[i],
            (value) => {
              states[i] =
                typeof value === "function" ? value(states[i]) : value;
            },
          ];
        },
        useRef: (initial) => {
          const i = refCursor++;
          return (refs[i] ??= { current: initial });
        },
      },
      "@/context/AuthContext": {
        useAuth: () => ({ logout: () => events.push("logout") }),
      },
      "@/components/ui/Toast/useToast": {
        useToast: () => ({ showToast: (toast) => toasts.push(toast) }),
      },
      "@/api/endpoints/auth.api": {
        authApi: {
          mandatoryChangePassword: async (input) => {
            calls.push(input);
            return mandatoryChangePassword();
          },
        },
      },
      "@/features/profile": { validatePasswordForm },
      "@/utils/apiErrors": { getApiErrorMessage },
    },
  );
  const render = () => {
    stateCursor = 0;
    refCursor = 0;
    return useMandatoryChangePassword();
  };
  const fill = (current, next, confirm) => {
    render().change("currentPassword", current);
    render().change("newPassword", next);
    render().change("confirmNewPassword", confirm);
  };
  const submit = async () => {
    lastResult = await render().submit({ preventDefault() {} });
    return render();
  };
  return {
    render,
    fill,
    submit,
    calls,
    toasts,
    events,
    result: () => lastResult,
  };
}

test("a wrong entry puts the message on its own field and sends nothing", async () => {
  const h = harness();
  h.fill("Temp1234", "abcdefg1", "abcdefg1");
  const view = await h.submit();
  assert.equal(view.fieldErrors.newPassword, RULE);
  assert.equal(view.fieldErrors.currentPassword, undefined);
  assert.equal(view.fieldErrors.confirmNewPassword, undefined);
  assert.equal(h.calls.length, 0);
  assert.equal(h.events.length, 0);
});

test("an empty current password and a mismatched confirmation each show on their field", async () => {
  const h = harness();
  h.fill("", "Abcdefg1", "Abcdefg2");
  const view = await h.submit();
  assert.equal(
    view.fieldErrors.currentPassword,
    "Enter your current password.",
  );
  assert.equal(view.fieldErrors.confirmNewPassword, "Passwords do not match.");
  assert.equal(h.calls.length, 0);
});

test("typing in a field clears only that field's message", async () => {
  const h = harness();
  h.fill("", "abc", "");
  await h.submit();
  h.render().change("newPassword", "Abcdefg1");
  const view = h.render();
  assert.equal(view.fieldErrors.newPassword, undefined);
  assert.ok(view.fieldErrors.currentPassword);
});

test("a correct entry is sent once, then shows the success toast and signs out", async () => {
  const h = harness();
  h.fill("Temp1234", "Abcdefg1", "Abcdefg1");
  const view = await h.submit();
  assert.deepEqual(JSON.parse(JSON.stringify(h.calls)), [
    {
      currentPassword: "Temp1234",
      newPassword: "Abcdefg1",
      confirmNewPassword: "Abcdefg1",
    },
  ]);
  assert.equal(h.toasts.length, 1);
  assert.equal(
    h.toasts[0].description,
    "Please sign in again with your new password.",
  );
  assert.deepEqual(h.events, ["logout"]);
  assert.equal(view.error, "");
});

test("a server refusal shows the server's message, keeps the values and does not sign out", async () => {
  const h = harness(async () => {
    throw {
      isAxiosError: true,
      response: {
        status: 400,
        data: { message: "Current password is incorrect." },
      },
    };
  });
  h.fill("Temp1234", "Abcdefg1", "Abcdefg1");
  const view = await h.submit();
  assert.equal(view.error, "Current password is incorrect.");
  assert.equal(view.values.currentPassword, "Temp1234");
  assert.equal(view.values.newPassword, "Abcdefg1");
  assert.equal(view.loading, false);
  assert.equal(h.toasts.length, 0);
  assert.equal(h.events.length, 0);
});

test("back to sign in signs out", () => {
  const h = harness();
  h.render().backToSignIn();
  assert.deepEqual(h.events, ["logout"]);
});

test("each eye button switches only its own field", () => {
  const h = harness();
  h.render().toggleShown("newPassword");
  const view = h.render();
  assert.deepEqual(JSON.parse(JSON.stringify(view.shown)), {
    currentPassword: false,
    newPassword: true,
    confirmNewPassword: false,
  });
  h.render().toggleShown("newPassword");
  assert.equal(h.render().shown.newPassword, false);
});

test("a failed check names the first wrong field so the page can move focus there", async () => {
  const h = harness();
  h.fill("Temp1234", "abcdefg1", "abcdefg2");
  await h.submit();
  assert.equal(h.result(), "newPassword");
  h.fill("", "Abcdefg1", "Abcdefg1");
  await h.submit();
  assert.equal(h.result(), "currentPassword");
});

test("a correct entry or a server refusal names no field", async () => {
  const h = harness();
  h.fill("Temp1234", "Abcdefg1", "Abcdefg1");
  await h.submit();
  assert.equal(h.result(), undefined);
});
