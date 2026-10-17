import assert from "node:assert/strict";
import fs from "node:fs";
import test from "node:test";
import vm from "node:vm";
import ts from "typescript";

const module = { exports: {} };
const code = ts.transpileModule(
  fs.readFileSync(
    new URL("./hooks/useVendorRegistration.ts", import.meta.url),
    "utf8",
  ),
  {
    compilerOptions: {
      module: ts.ModuleKind.CommonJS,
      target: ts.ScriptTarget.ES2022,
    },
  },
).outputText;
vm.runInNewContext(`${code}\nmodule.exports.validateStep = validateStep;`, {
  module,
  exports: module.exports,
  require: () => ({}),
});
const { initialWizardState, validateStep } = module.exports;

for (const field of ["governmentIdPhoto", "businessDocumentPhoto"]) {
  test(`registration rejects an empty ${field} before submission`, () => {
    const form = {
      ...initialWizardState,
      businessId: "MM-2026-0010",
      governmentIdType: "NationalId",
      governmentIdPhoto: {
        name: "government.pdf",
        type: "application/pdf",
        size: 1024,
      },
      businessDocumentPhoto: {
        name: "permit.pdf",
        type: "application/pdf",
        size: 1024,
      },
    };
    form[field] = { ...form[field], size: 0 };

    const errors = validateStep(3, form);

    assert.match(errors[field] ?? "", /cannot be empty/i);
    assert.equal(Object.keys(errors).length, 1);
  });
}
