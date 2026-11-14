import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import ts from "typescript";

const source = await readFile(
  new URL("./searchMatch.ts", import.meta.url),
  "utf8",
);
const output = ts.transpileModule(source, {
  compilerOptions: {
    module: ts.ModuleKind.ESNext,
    target: ts.ScriptTarget.ES2020,
  },
}).outputText;
const { searchParts, exactMatchesFirst } = await import(
  `data:text/javascript;base64,${Buffer.from(output).toString("base64")}`
);

const names = (items) => items.map((item) => item.name);
const byName = (item) => [item.name];

test("search parts mark every match regardless of capital letters", () => {
  assert.deepEqual(searchParts("Juan Dela Cruz", "cruz"), [
    { text: "Juan Dela ", match: false },
    { text: "Cruz", match: true },
  ]);
  assert.deepEqual(searchParts("CRUZ and cruz", " Cruz "), [
    { text: "CRUZ", match: true },
    { text: " and ", match: false },
    { text: "cruz", match: true },
  ]);
});

test("search parts treat typed symbols as plain text", () => {
  assert.deepEqual(searchParts("Stall (A-12)", "(a-12)"), [
    { text: "Stall ", match: false },
    { text: "(A-12)", match: true },
  ]);
  assert.deepEqual(searchParts("Fee 1.5", "."), [
    { text: "Fee 1", match: false },
    { text: ".", match: true },
    { text: "5", match: false },
  ]);
});

test("search parts leave text unmarked when nothing is typed", () => {
  assert.deepEqual(searchParts("Market", ""), [
    { text: "Market", match: false },
  ]);
  assert.deepEqual(searchParts("Market", "   "), [
    { text: "Market", match: false },
  ]);
});

test("whole-word matches come first and keep their order", () => {
  const items = [
    { name: "Cruzada Store" },
    { name: "Juan Cruz" },
    { name: "Ana Cruzado" },
    { name: "Bakery CRUZ" },
  ];
  assert.deepEqual(names(exactMatchesFirst(items, "cruz", byName)), [
    "Juan Cruz",
    "Bakery CRUZ",
    "Cruzada Store",
    "Ana Cruzado",
  ]);
});

test("a match touching a letter or digit is not exact", () => {
  const items = [{ name: "A-120" }, { name: "Stall a-12" }, { name: "A-12" }];
  assert.deepEqual(names(exactMatchesFirst(items, " A-12 ", byName)), [
    "Stall a-12",
    "A-12",
    "A-120",
  ]);
});

test("any searched value can make a row exact, and no search keeps the order", () => {
  const items = [
    { name: "Fresh Meat", note: "Pork" },
    { name: "Dry goods", note: "Rice and sugar" },
  ];
  const values = (item) => [item.name, item.note];
  assert.deepEqual(names(exactMatchesFirst(items, "rice", values)), [
    "Dry goods",
    "Fresh Meat",
  ]);
  assert.deepEqual(names(exactMatchesFirst(items, "", values)), [
    "Fresh Meat",
    "Dry goods",
  ]);
});
