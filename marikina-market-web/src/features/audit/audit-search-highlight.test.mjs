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

const jsx = { "react/jsx-runtime": jsxRuntime };
const stub = tag => () => React.createElement(tag);
const constants = { AUDIT_MODULE_OPTIONS: [{ value: "Security", label: "Security" }] };
const utils = load("./audit.utils.ts", { "./audit.constants": constants });
const SearchHighlight = load("../../components/ui/SearchHighlight/SearchHighlight.tsx", {
  ...jsx, "@/utils/searchMatch": load("../../utils/searchMatch.ts"),
}).default;
const AuditActivityCell = load("./components/AuditActivityCell.tsx", {
  ...jsx, "../audit.utils": utils, "@/components/ui/SearchHighlight": { default: SearchHighlight },
}).default;
const AuditHistory = load("./components/AuditHistory.tsx", {
  ...jsx,
  "@/components/ui/Table/Table": { default: load("../../components/ui/Table/Table.tsx", jsx).Table },
  "@/components/ui/Pagination/Pagination": { default: stub("nav") },
  "@/components/ui/Badge/Badge": { Badge: stub("span") },
  "@/components/ui/Button/Button": { default: stub("button") },
  "../audit.utils": utils,
  "../audit.constants": constants,
  "./AuditFilters": { default: stub("div") },
  "./AuditActivityCell": { default: AuditActivityCell },
  "./AuditActorCell": { default: stub("div") },
  "./AuditResultBadge": { default: stub("span") },
  "./AuditViewButton": { default: stub("button") },
  "./AuditRequestMessage": { default: stub("p") },
}).default;

const record = { id: 5, timestamp: "2026-11-16T02:00:00Z", userId: 7, firstName: "Ana", lastName: "Reyes", role: "HeadAdmin",
  action: "SaveNewInspection", module: "Security", result: "Success" };
const marks = html => [...html.matchAll(/<mark[^>]*>([^<]*)<\/mark>/g)].map(m => m[1]);
const renderCell = search => renderToStaticMarkup(React.createElement(AuditActivityCell, { record, search }));

test("the activity cell highlights the search in the readable activity name, in any capital letters", () => {
  assert.match(renderCell("INSPECTION"), /Save New <mark[^>]*>Inspection<\/mark>/);
  assert.deepEqual(marks(renderCell("new")), ["New"]);
});

test("the activity cell does not highlight the audit number, which the search does not look at", () => {
  const html = renderCell("5");
  assert.match(html, /Audit #5/);
  assert.deepEqual(marks(html), []);
});

test("the activity cell shows no highlight without a search", () => {
  assert.ok(!renderCell("").includes("<mark"));
});

test("the history table passes its search text to the activity column and clears it when the search is cleared", () => {
  const model = { items: [record], search: "inspection", error: "", isFetching: false, isFiltering: false, isExporting: false,
    hasFilters: true, page: 1, totalPages: 1, canNext: false, rangeLabel: "", view() {}, retry() {}, resetFilters() {}, changePage() {} };
  const render = search => renderToStaticMarkup(React.createElement(AuditHistory, { model: { ...model, search } }));
  assert.deepEqual(marks(render("inspection")), ["Inspection"]);
  assert.deepEqual(marks(render("")), []);
});
