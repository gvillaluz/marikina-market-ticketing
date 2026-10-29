import assert from "node:assert/strict";
import fs from "node:fs";
import test from "node:test";
import vm from "node:vm";
import ts from "typescript";

function harness() {
  const calls = [];
  const client = Object.fromEntries(["get", "post", "put"].map(method => [method,
    async (...args) => { calls.push({ method, args }); return { data: { id: 17 } }; }]));
  const module = { exports: {} };
  vm.runInNewContext(ts.transpileModule(fs.readFileSync(new URL("./persons.api.ts", import.meta.url), "utf8"), {
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 },
  }).outputText, { module, exports: module.exports, require: () => ({ default: client }) });
  return { api: module.exports.personsApi, calls };
}

test("person writes use admin routes and send only editable normalized fields", async () => {
  const { api, calls } = harness();
  const request = { fullName: " E2E Elena Reyes ", address: " Market Lane ", phoneNumber: " ", id: 8, createdAt: "ignored" };
  await api.save(null, request);
  assert.equal(calls[0].method, "post");
  assert.equal(calls[0].args[0], "/admin/persons");
  assert.equal(JSON.stringify(calls[0].args[1]), JSON.stringify({ fullName: "E2E Elena Reyes", address: "Market Lane", phoneNumber: null }));
  assert.equal(request.phoneNumber, " ");
  await api.save(17, { ...request, phoneNumber: "09171234567" });
  assert.equal(calls[1].method, "put");
  assert.equal(calls[1].args[0], "/admin/persons/17");
  assert.equal(calls[1].args[1].phoneNumber, "09171234567");
});

test("person reads use shared staff routes and preserve search and offset", async () => {
  const { api, calls } = harness();
  await api.list("Reyes", 10);
  await api.get(17);
  assert.equal(calls[0].args[0], "/persons");
  assert.equal(calls[0].args[1].params.search, "Reyes");
  assert.equal(calls[0].args[1].params.offset, 10);
  assert.equal(calls[1].args[0], "/persons/17");
});
