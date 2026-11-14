import assert from "node:assert/strict";
import fs from "node:fs";
import test from "node:test";
import vm from "node:vm";
import ts from "typescript";

function harness() {
  const calls = [];
  const client = {
    post: async (...args) => {
      calls.push(args);
      return { data: {} };
    },
  };
  const module = { exports: {} };
  vm.runInNewContext(
    ts.transpileModule(
      fs.readFileSync(new URL("./auth.api.ts", import.meta.url), "utf8"),
      {
        compilerOptions: {
          module: ts.ModuleKind.CommonJS,
          target: ts.ScriptTarget.ES2022,
        },
      },
    ).outputText,
    { module, exports: module.exports, require: () => ({ default: client }) },
  );
  return { api: module.exports.authApi, calls };
}

const input = {
  currentPassword: "Current1",
  newPassword: "Abcdefg1",
  confirmNewPassword: "Abcdefg1",
};

test("a normal password change posts to /auth/change-password with the three fields", async () => {
  const { api, calls } = harness();
  await api.changePassword(input);
  assert.equal(calls.length, 1);
  assert.equal(calls[0][0], "/auth/change-password");
  assert.deepEqual(calls[0][1], input);
});

test("the forced password change still posts to /auth/mandatory-change-password", async () => {
  const { api, calls } = harness();
  await api.mandatoryChangePassword(input);
  assert.equal(calls[0][0], "/auth/mandatory-change-password");
});

test("website sign-out posts to /auth/logout-web with no body so the server deletes the cookie", async () => {
  const { api, calls } = harness();
  await api.logoutWeb();
  assert.equal(calls.length, 1);
  assert.equal(calls[0][0], "/auth/logout-web");
  assert.equal(calls[0][1], undefined);
});
