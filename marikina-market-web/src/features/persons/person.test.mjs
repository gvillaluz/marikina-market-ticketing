import assert from "node:assert/strict";
import fs from "node:fs";
import test from "node:test";
import vm from "node:vm";
import ts from "typescript";
import React from "react";
import { renderToStaticMarkup } from "react-dom/server";

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
const validation = load("./person.validation.ts");

function harness(id = null) {
  const slots = []; let cursor = 0; let effects = []; let save; let calls = 0; let closes = 0; let refreshes = 0;
  const record = { data: undefined, isFetching: false, isError: false };
  const hook = load("./hooks/usePersonForm.ts", {
    react: {
      useState: initial => { const index = cursor++; if (!(index in slots)) slots[index] = initial;
        return [slots[index], value => { slots[index] = typeof value === "function" ? value(slots[index]) : value; }]; },
      useRef: initial => { const index = cursor++; return slots[index] ??= { current: initial }; },
      useEffect: (effect, deps) => { const index = cursor++; const previous = slots[index];
        if (!previous || deps.some((value, i) => value !== previous[i])) effects.push(effect); slots[index] = deps; },
    },
    "@tanstack/react-query": { useQuery: () => record },
    "@/api/endpoints/persons.api": { personsApi: { save: async (...args) => { calls++; return save?.(...args); } } },
    "@/utils/apiErrors": { getApiErrorMessage: (error, fallback) => error?.message || fallback },
    "../person.validation": validation,
  }).usePersonForm;
  const render = () => { cursor = 0; effects = []; const value = hook(true, id, async () => { refreshes++; }, () => { closes++; }); effects.forEach(effect => effect()); return value; };
  render();
  return { render, record, save: fn => { save = fn; }, calls: () => calls, closes: () => closes, refreshes: () => refreshes };
}
const fill = h => { const state = h.render(); state.update("fullName", "E2E Elena Reyes"); state.update("address", "12 Market Lane, Marikina City"); };

test("required fields and malformed phone stop submission", async () => {
  const h = harness(); await h.render().submit(); assert.equal(h.calls(), 0);
  fill(h); h.render().update("phoneNumber", "invalid"); await h.render().submit(); assert.equal(h.calls(), 0);
  assert.ok(h.render().errors.phoneNumber);
});

test("pending save blocks duplicate clicks; successful optional-phone save closes and refreshes", { timeout: 2000 }, async () => {
  const h = harness(); fill(h); let release;
  h.save(() => new Promise(resolve => { release = resolve; }));
  const state = h.render(); const first = state.submit(); await state.submit(); assert.equal(h.calls(), 1);
  assert.equal(h.render().saving, true); release({ id: 1 }); await first;
  assert.equal(h.closes(), 1); assert.equal(h.refreshes(), 1); assert.equal(h.render().saving, false);
});

test("failed create retains draft and blocks retry until explicit registry check", async () => {
  const h = harness(); fill(h); h.save(() => { throw Error("Connection lost"); });
  await h.render().submit(); let state = h.render();
  assert.equal(state.form.fullName, "E2E Elena Reyes"); assert.equal(state.submitError, "Connection lost");
  assert.equal(state.uncertainCreate, true); assert.equal(state.saving, false); assert.equal(h.closes(), 0);
  await state.submit(); assert.equal(h.calls(), 1);
  state.confirmNotSaved(); h.save(() => ({ id: 1 })); await h.render().submit(); assert.equal(h.calls(), 2);
});

test("edit loading and failures block writes; reconnect cannot overwrite an edited draft", async () => {
  const h = harness(17); h.record.isFetching = true; await h.render().submit(); assert.equal(h.calls(), 0);
  h.record.isFetching = false; h.record.data = { fullName: "E2E Elena Reyes", address: "Market Lane", phoneNumber: null };
  h.render(); h.render().update("fullName", "E2E Elena Santos");
  h.record.data = { ...h.record.data }; h.render(); assert.equal(h.render().form.fullName, "E2E Elena Santos");
  h.record.isError = true; await h.render().submit(); assert.equal(h.calls(), 0);
  h.record.isError = false; h.save(() => { throw Error("Save failed"); }); await h.render().submit();
  assert.equal(h.render().form.fullName, "E2E Elena Santos"); assert.equal(h.render().uncertainCreate, false);
  h.save(() => ({ id: 17 })); await h.render().submit(); assert.equal(h.closes(), 1);
});

test("person validation accepts blank phone and enforces length boundaries", () => {
  assert.equal(Object.keys(validation.validatePerson({ fullName: "Name", address: "Address", phoneNumber: " " })).length, 0);
  assert.ok(validation.validatePerson({ fullName: "n".repeat(201), address: "a".repeat(501), phoneNumber: "09" }).fullName);
  assert.ok(validation.validatePerson({ fullName: "Name", address: "a".repeat(501), phoneNumber: null }).address);
});

test("registry renders loading, empty, error and distinct same-name rows as text", () => {
  const jsx = { "react/jsx-runtime": ReactJsx(), react: React };
  const icon = name => () => React.createElement("svg", { "data-icon": name });
  const icons = { "lucide-react": { Search: icon("search"), Eye: icon("eye"), RefreshCw: icon("refresh"), Download: icon("download"), Printer: icon("printer"), CircleAlert: icon("alert"), FolderSearch: icon("folder") } };
  const Table = load("../../components/ui/Table/Table.tsx", jsx).Table;
  const Pagination = load("../../components/ui/Pagination/Pagination.tsx", jsx).default;
  const Button = load("../../components/ui/Button/Button.tsx", jsx).default;
  const Records = {
    RecordsPanel: load("../../components/ui/Records/RecordsPanel.tsx", jsx).RecordsPanel,
    RecordsToolbar: load("../../components/ui/Records/RecordsToolbar.tsx", { ...jsx, ...icons }).RecordsToolbar,
    RecordsFooter: load("../../components/ui/Records/RecordsFooter.tsx", { ...jsx, ...icons, "@/components/ui/Pagination": { default: Pagination } }).RecordsFooter,
    RecordsState: load("../../components/ui/Records/RecordsState.tsx", { ...jsx, ...icons }).RecordsState,
    RecordActions: load("../../components/ui/Records/RecordActions.tsx", { ...jsx, ...icons }).RecordActions,
  };
  const formatters = load("../../utils/formatters.ts", { "./constants": { APP_CONSTANTS: {} } });
  const Registry = load("./components/PersonRegistry.tsx", { ...jsx,
    "@/components/ui/Table": { default: Table }, "@/components/ui/Button": { default: Button },
    "@/components/ui/Records": Records, "@/utils/formatters": formatters }).default;
  const state = { persons: [], search: "", total: 0, page: 1, hasMore: false, showForm() {}, setSearch() {}, setPage() {}, retry() {} };
  const render = overrides => renderToStaticMarkup(React.createElement(Registry, { ...state, ...overrides }));
  assert.match(render({ loading: true }), /Loading people/);
  assert.match(render({}), /No people recorded yet/);
  assert.match(render({ search: "zzz" }), /No people match this search/);
  const failed = render({ error: "API unavailable" });
  assert.match(failed, /API unavailable/);
  assert.match(failed, /Try again/);
  assert.doesNotMatch(failed, /Showing/);
  const person = { id: 1, fullName: "<E2E Elena>", address: "Market Lane", phoneNumber: null, createdAt: "2026-11-01T06:00:00Z" };
  const html = render({ persons: [person, { ...person, id: 2, phoneNumber: "09171234567", createdAt: "not a date" }], total: 2 });
  // Per row, the name shows once in its cell and once in the action button's label.
  assert.equal((html.match(/&lt;E2E Elena&gt;/g) ?? []).length, 4);
  assert.match(html, /Showing 1–2 of 2 people/);
  assert.match(html, /Date added/);
  assert.match(html, /Nov 1, 2026/);
  assert.match(html, /09171234567/);
  assert.equal((html.match(/aria-label="View person/g) ?? []).length, 2);
});

test("saved person details show that person's citation history; a new person shows none", () => {
  const Button = load("../../components/ui/Button/Button.tsx", { "react/jsx-runtime": ReactJsx(), react: React }).default;
  const state = {
    form: { fullName: "E2E Elena Reyes", address: "12 Market Lane, Marikina City", phoneNumber: null },
    errors: {}, saving: false, loading: false, loadError: "", submitError: "", uncertainCreate: false,
    createdAt: "2026-11-01T02:00:00Z", update() {}, submit() {}, retry() {}, confirmNotSaved() {},
  };
  const Modal = load("./components/PersonFormModal.tsx", {
    "react/jsx-runtime": ReactJsx(), react: React,
    "@/components/ui/Button": { default: Button },
    "@/components/ui/Modal": { default: ({ open, children }) => open ? React.createElement("div", null, children) : null },
    "../hooks/usePersonForm": { usePersonForm: () => state },
    "@/features/tickets": { PersonTicketHistory: ({ personId }) => React.createElement("section", null, `Citation history for person ${personId}`) },
  }).default;
  const render = personId => renderToStaticMarkup(React.createElement(Modal, { open: true, personId, onClose() {}, onSaved: async () => {} }));
  assert.match(render(17), /Citation history for person 17/);
  assert.match(render(17), /E2E Elena Reyes/);
  assert.doesNotMatch(render(null), /Citation history/);
});

// Use React's actual JSX runtime for production component rendering.
import * as jsxRuntime from "react/jsx-runtime";
function ReactJsx() { return jsxRuntime; }
