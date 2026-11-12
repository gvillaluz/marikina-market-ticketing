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

class ApiRequestError extends Error {
  constructor(message) {
    super(message);
    this.serverMessage = message;
  }
}

function harness(changePassword) {
  const states = [];
  const refs = [];
  const events = [];
  let stateCursor = 0;
  let refCursor = 0;
  let closed = 0;
  const useChangePassword = load("./hooks/useChangePassword.ts", {
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
    },
    "@/api/endpoints/auth.api": {
      authApi: {
        changePassword: async (values) => {
          events.push(["changePassword", values]);
          return changePassword();
        },
        mandatoryChangePassword: async () => {
          events.push(["mandatoryChangePassword"]);
        },
      },
    },
    "@/context/AuthContext": {
      useAuth: () => ({
        logout: () => events.push(["logout"]),
        clearMustChangePassword: () => events.push(["clearMustChange"]),
      }),
    },
    "@/components/ui/Toast/useToast": {
      useToast: () => ({ showToast: (toast) => events.push(["toast", toast]) }),
    },
    "@/utils/apiErrors": {
      ApiRequestError,
      getApiErrorMessage: (error, fallback) => error?.serverMessage || fallback,
    },
    "../profile.validation": {
      validatePasswordForm: (values) =>
        values.newPassword === "Abcdefg1" ? {} : { newPassword: "bad" },
    },
  }).useChangePassword;
  const render = () => {
    stateCursor = 0;
    refCursor = 0;
    return useChangePassword(() => {
      closed++;
    });
  };
  const fill = () => {
    for (const [field, value] of [
      ["currentPassword", "Current1"],
      ["newPassword", "Abcdefg1"],
      ["confirmNewPassword", "Abcdefg1"],
    ])
      render().change(field, value);
  };
  return { render, fill, events, closed: () => closed };
}

test("a successful change calls /auth/change-password, shows the message, and signs out", async () => {
  const h = harness(async () => {});
  h.fill();
  await h.render().submit();
  assert.deepEqual(
    h.events.map(([name]) => name),
    ["changePassword", "toast", "logout"],
  );
  assert.equal(
    JSON.stringify(h.events[0][1]),
    JSON.stringify({
      currentPassword: "Current1",
      newPassword: "Abcdefg1",
      confirmNewPassword: "Abcdefg1",
    }),
  );
  assert.equal(h.events[1][1].title, "Password changed");
  assert.equal(
    h.events[1][1].description,
    "Please sign in again with your new password.",
  );
});

test("a server rejection shows the server message, signs nobody out, and keeps the typed values", async () => {
  const h = harness(async () => {
    throw new ApiRequestError("Incorrect password.");
  });
  h.fill();
  await h.render().submit();
  const view = h.render();
  assert.equal(view.error, "Incorrect password.");
  assert.equal(view.isSaving, false);
  assert.equal(view.values.currentPassword, "Current1");
  assert.equal(view.values.newPassword, "Abcdefg1");
  assert.deepEqual(
    h.events.map(([name]) => name),
    ["changePassword"],
  );
  assert.equal(h.closed(), 0);
});

test("the matches hint appears only when the new password passes the rule and the confirmation matches", () => {
  const h = harness(async () => {});
  h.render().change("newPassword", "abcdef");
  h.render().change("confirmNewPassword", "abcdef");
  assert.equal(h.render().matches, false);
  h.render().change("newPassword", "Abcdefg1");
  assert.equal(h.render().matches, false);
  h.render().change("confirmNewPassword", "Abcdefg1");
  assert.equal(h.render().matches, true);
});
