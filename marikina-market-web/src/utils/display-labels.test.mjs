import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import ts from "typescript";

async function compile(relativePath) {
  const source = await readFile(new URL(relativePath, import.meta.url), "utf8");
  const output = ts.transpileModule(source, {
    compilerOptions: {
      module: ts.ModuleKind.ESNext,
      target: ts.ScriptTarget.ES2020,
    },
  }).outputText;
  return `data:text/javascript;base64,${Buffer.from(output).toString("base64")}`;
}

const { recordStatusLabel } = await import(await compile("./constants.ts"));

test("InProgress shows as In Progress", () => {
  assert.equal(recordStatusLabel("InProgress"), "In Progress");
});

test("single-word statuses keep their text", () => {
  assert.equal(recordStatusLabel("Paid"), "Paid");
  assert.equal(recordStatusLabel("Overdue"), "Overdue");
  assert.equal(recordStatusLabel("Pending"), "Pending");
});

test("unknown text is shown as it is", () => {
  assert.equal(recordStatusLabel("Unknown"), "Unknown");
});
