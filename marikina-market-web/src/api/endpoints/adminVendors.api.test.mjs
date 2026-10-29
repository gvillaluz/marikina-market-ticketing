import assert from "node:assert/strict";
import fs from "node:fs";
import test from "node:test";
import vm from "node:vm";
import ts from "typescript";

function loadApi() {
  const calls = [];
  const client = Object.fromEntries(["post", "put"].map(method => [method,
    async (route, body) => { calls.push({ method, route, body }); return { data: { id: 28 } }; },
  ]));
  const module = { exports: {} };
  const code = ts.transpileModule(fs.readFileSync(new URL("./adminVendors.api.ts", import.meta.url), "utf8"), {
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 },
  }).outputText;
  vm.runInNewContext(code, {
    module, exports: module.exports,
    require: name => name === "@/api/client" ? { default: client } : { ApiRequestError: Error },
  });
  return { api: module.exports.adminVendorsApi, calls };
}

for (const id of [null, 28]) {
  test(`business ${id === null ? "create" : "edit"} sends blank optional contact values as null`, async () => {
    const { api, calls } = loadApi();
    const request = { businessAccountNumber: "000REV2801", businessName: "Reyes Fish Store", phoneNumber: "  ", email: "" };
    await api.saveBusiness(id, request);
    assert.equal(calls[0].method, id === null ? "post" : "put");
    assert.equal(calls[0].body.email, null);
    assert.equal(calls[0].body.phoneNumber, null);
    assert.equal(calls[0].body.businessAccountNumber, "000REV2801");
    assert.equal(request.email, "");
    assert.equal(request.phoneNumber, "  ");
  });
}

test("business save preserves entered contact values for server validation", async () => {
  const { api, calls } = loadApi();
  await api.saveBusiness(null, { phoneNumber: "09171234567", email: "owner@example.test" });
  assert.equal(calls[0].body.phoneNumber, "09171234567");
  assert.equal(calls[0].body.email, "owner@example.test");
  await api.saveBusiness(28, { phoneNumber: "invalid", email: "invalid" });
  assert.equal(calls[1].body.phoneNumber, "invalid");
  assert.equal(calls[1].body.email, "invalid");
});
