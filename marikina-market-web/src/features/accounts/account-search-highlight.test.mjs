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
const SearchHighlight = load("../../components/ui/SearchHighlight/SearchHighlight.tsx", {
  ...jsx, "@/utils/searchMatch": load("../../utils/searchMatch.ts"),
}).default;
const constants = load("./accounts.constants.ts", {
  "@/api/types/common.types": { USER_ROLE_LABELS: { MarketEnforcer: "Market Enforcer" } },
});
const AccountRow = load("./components/AccountRow.tsx", {
  ...jsx,
  "../accounts.constants": constants,
  "../hooks/useAccountAvatar": { useAccountAvatar: () => ({ src: undefined, onError() {} }) },
  "@/components/ui/UrlImage": { default: () => React.createElement("span") },
  "@/components/ui/SearchHighlight": { default: SearchHighlight },
}).default;
const AccountDirectory = load("./components/AccountDirectory.tsx", {
  ...jsx,
  "lucide-react": { Search: () => React.createElement("svg") },
  "@/components/ui/Pagination": { default: () => React.createElement("nav") },
  "../accounts.constants": constants,
  "./AccountRow": { default: AccountRow },
  "./AccountRowsSkeleton": { default: () => React.createElement("tr") },
  "./AccountMessage": { default: () => React.createElement("p") },
}).default;

const account = { id: 2, firstName: "Ben", middleName: null, lastName: "Dela-Cruz", username: "HAD0002-test",
  email: "cruz@mail.invalid", phoneNumber: "09171234567", role: "MarketEnforcer", status: "Active", profileUrl: null };
const renderRow = (search, overrides = {}) => renderToStaticMarkup(
  React.createElement("table", null, React.createElement("tbody", null,
    React.createElement(AccountRow, { account: { ...account, ...overrides }, search, onManage() {} }))));
// The four values in the order they are shown: name, username, email, phone.
const marked = html => [...html.matchAll(/<p[^>]*>([^]*?)<\/p>/g)]
  .map(m => [...m[1].matchAll(/<mark[^>]*>([^<]*)<\/mark>/g)].map(x => x[1]));

test("the account row highlights the search in the name and email, in any capital letters", () => {
  assert.deepEqual(marked(renderRow("CRUZ")), [["Cruz"], [], ["cruz"], []]);
});

test("the account row highlights the username and the phone number", () => {
  assert.deepEqual(marked(renderRow("had0002")), [[], ["HAD0002"], [], []]);
  assert.deepEqual(marked(renderRow("0917")), [[], [], [], ["0917"]]);
});

test("the account row does not highlight the stand-in texts for a missing email or phone", () => {
  const html = renderRow("email", { email: "", phoneNumber: "" });
  assert.match(html, /No email provided/);
  assert.ok(!html.includes("<mark"));
  assert.ok(!renderRow("phone", { email: "", phoneNumber: "" }).includes("<mark"));
});

test("the account row shows no highlight without a search", () => {
  assert.ok(!renderRow("").includes("<mark"));
});

test("the directory passes its search text to the rows and clears it when the search is cleared", () => {
  const model = { search: "cruz", role: "all", isLoading: false, error: "", items: [account], isFetching: false,
    page: 1, totalPages: 1, canNext: false, rangeLabel: "", changeRole() {}, changeSearch() {}, changePage() {}, retry() {} };
  const render = search => renderToStaticMarkup(React.createElement(AccountDirectory, { model: { ...model, search }, onManage() {} }));
  assert.match(render("cruz"), /<mark[^>]*>Cruz<\/mark>/);
  assert.ok(!render("").includes("<mark"));
});
