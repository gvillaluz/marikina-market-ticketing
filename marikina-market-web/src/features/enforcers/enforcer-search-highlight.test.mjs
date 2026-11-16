import assert from "node:assert/strict";
import fs from "node:fs";
import test from "node:test";
import vm from "node:vm";
import ts from "typescript";
import React from "react";
import { renderToStaticMarkup } from "react-dom/server";
import * as jsxRuntime from "react/jsx-runtime";

function load(file, dependencies = {}) {
  const module = { exports: {} };
  const code = ts.transpileModule(fs.readFileSync(new URL(file, import.meta.url), "utf8"), {
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022, jsx: ts.JsxEmit.ReactJSX, esModuleInterop: true },
  }).outputText;
  vm.runInNewContext(code, { module, exports: module.exports, require: name => {
    if (name.endsWith(".css")) return { __esModule: true, default: new Proxy({}, { get: (_, key) => String(key) }) };
    assert.ok(name in dependencies, `Unexpected import ${name}`);
    return { __esModule: true, ...dependencies[name] };
  } });
  return module.exports;
}

const icon = () => () => React.createElement("svg");
const SearchHighlight = load("../../components/ui/SearchHighlight/SearchHighlight.tsx", {
  "react/jsx-runtime": jsxRuntime, "@/utils/searchMatch": load("../../utils/searchMatch.ts"),
}).default;
const EnforcerCard = load("./components/EnforcerCard.tsx", {
  "react/jsx-runtime": jsxRuntime,
  "lucide-react": { ArrowRight: icon(), Ticket: icon(), TriangleAlert: icon() },
  "@/components/ui/UrlImage": { default: () => React.createElement("span") },
  "@/components/ui/SearchHighlight": { default: SearchHighlight },
}).default;

const card = { name: "Dela-Cruz, Ben", initials: "DB", profileUrl: null, badgeNo: "HAD0002-test", status: "Active",
  warnings: 1, tickets: 3, onViewInspections() {} };
const render = search => renderToStaticMarkup(React.createElement(EnforcerCard, { ...card, search }));
const marks = html => [...html.matchAll(/<mark[^>]*>([^<]*)<\/mark>/g)].map(m => m[1]);
const part = (html, name) => html.match(new RegExp(`class="${name}">([^]*?)</span>`))[1];

test("the card highlights the search in the name, in any capital letters", () => {
  const html = render("CRUZ");
  assert.deepEqual(marks(part(html, "name")), ["Cruz"]);
  assert.deepEqual(marks(part(html, "badgeNo")), []);
});

test("the card highlights the search in the ID line but not in its ID label", () => {
  const html = render("had0002");
  assert.deepEqual(marks(part(html, "badgeNo")), ["HAD0002"]);
  assert.deepEqual(marks(part(html, "name")), []);
  assert.deepEqual(marks(part(render("id"), "badgeNo")), []);
});

test("the card shows no highlight without a search", () => {
  assert.ok(!render("").includes("<mark"));
});
