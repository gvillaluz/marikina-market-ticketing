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

const { recordStatusLabel, violationCategoryLabel, violationCommittedLabels } =
  await import(await compile("./constants.ts"));

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

test("violation categories show readable names", () => {
  assert.equal(violationCategoryLabel("WeightMeasures"), "Weights & Measures");
  assert.equal(violationCategoryLabel("DressCode"), "Dress Code");
  assert.equal(violationCategoryLabel("Traffic"), "Traffic");
});

test("Others shows the specific category typed on its ordinance", () => {
  const detail = {
    categories: ["Traffic", "Others"],
    violations: [
      { specificCategory: null },
      { specificCategory: "Mobile vendors near the gate" },
    ],
  };
  assert.deepEqual(violationCommittedLabels(detail), [
    "Traffic",
    "Mobile vendors near the gate",
  ]);
});

test("Others without a specific category stays as Others", () => {
  const detail = {
    categories: ["Others"],
    violations: [{ specificCategory: null }],
  };
  assert.deepEqual(violationCommittedLabels(detail), ["Others"]);
});
