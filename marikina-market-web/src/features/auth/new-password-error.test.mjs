import assert from "node:assert/strict";
import fs from "node:fs";
import test from "node:test";
import vm from "node:vm";
import ts from "typescript";

const module = { exports: {} };
vm.runInNewContext(
  ts.transpileModule(
    fs.readFileSync(
      new URL("../profile/profile.validation.ts", import.meta.url),
      "utf8",
    ),
    {
      compilerOptions: {
        module: ts.ModuleKind.CommonJS,
        target: ts.ScriptTarget.ES2022,
      },
    },
  ).outputText,
  { module, exports: module.exports },
);
const { newPasswordError } = module.exports;

const RULE = "Use at least 8 characters, with a number and a capital letter.";

test("newPasswordError accepts a password that meets the rule", () => {
  assert.equal(newPasswordError("Abcdefg1"), undefined);
});

test("newPasswordError refuses short, no-number and no-capital passwords", () => {
  for (const value of ["Abc1", "Abcdefgh", "abcdefg1", ""])
    assert.equal(newPasswordError(value), RULE, value);
});
