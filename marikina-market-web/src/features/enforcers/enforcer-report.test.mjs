import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";
import test from "node:test";
import vm from "node:vm";
import React from "react";
import { renderToStaticMarkup } from "react-dom/server";
import ts from "typescript";

// The all-enforcers report. The data hook is replaced with fixed answers so each case (loaded,
// loading, failed, bad dates, empty) can be drawn; everything the page draws is the real code.
// Every expected value is worked out by hand.

const require = createRequire(import.meta.url);
const realRouter = require("react-router-dom");
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");

function load(relative, overrides = {}, cache = new Map()) {
  const file = path.resolve(root, relative);
  if (cache.has(file)) return cache.get(file);
  const module = { exports: {} };
  cache.set(file, module.exports);
  const code = ts.transpileModule(fs.readFileSync(file, "utf8"), {
    compilerOptions: {
      module: ts.ModuleKind.CommonJS,
      target: ts.ScriptTarget.ES2022,
      jsx: ts.JsxEmit.ReactJSX,
      esModuleInterop: true,
    },
  }).outputText;
  vm.runInNewContext(
    code,
    {
      module,
      exports: module.exports,
      Date,
      Intl,
      require(id) {
        if (id in overrides) return { __esModule: true, ...overrides[id] };
        if (id.endsWith(".css"))
          return {
            __esModule: true,
            default: new Proxy({}, { get: (_, key) => key }),
          };
        if (!id.startsWith(".") && !id.startsWith("@/")) return require(id);
        const base = id.startsWith("@/")
          ? path.resolve(root, id.slice(2))
          : path.resolve(path.dirname(file), id);
        const resolved = [base, `${base}.ts`, `${base}.tsx`, `${base}/index.ts`].find(
          (candidate) => fs.existsSync(candidate) && fs.statSync(candidate).isFile(),
        );
        assert.ok(resolved, `Cannot resolve ${id}`);
        const alias = `@/${path
          .relative(root, resolved)
          .replaceAll("\\", "/")
          .replace(/\.tsx?$/, "")}`;
        if (alias in overrides) return { __esModule: true, ...overrides[alias] };
        return load(path.relative(root, resolved), overrides, cache);
      },
    },
    { filename: file },
  );
  return module.exports;
}

const utils = load("features/enforcers/enforcerReport.utils.ts");
const { toCsv } = load("utils/tableExport.ts");

const row = (overrides) => ({
  enforcerId: 8, username: "ENF-0008", firstName: "Juan", lastName: "Dela Cruz", status: "Active",
  warnings: 1, tickets: 4, totalRecords: 5, settledTickets: 2, openTickets: 2,
  finesCharged: 3000, finesSettled: 2000, daysWithRecords: 3,
  // Thu 5 Nov 01:00 in the Philippines, still 4 Nov in UTC.
  lastRecordAt: "2026-11-04T17:00:00Z",
  ...overrides,
});
const report = {
  dateRange: { from: "2026-11-02", to: "2026-11-05" },
  enforcers: [
    row(),
    row({
      enforcerId: 11, username: "ENF-0011", firstName: "Mia", lastName: "Santos", status: "Inactive",
      warnings: 2, tickets: 3, totalRecords: 5, settledTickets: 1, openTickets: 2,
      finesCharged: 2300.5, finesSettled: 800, daysWithRecords: 2, lastRecordAt: "2026-11-03T04:00:00Z",
    }),
    row({
      enforcerId: 10, username: "ENF-0010", firstName: "Leo", lastName: "Bautista",
      warnings: 0, tickets: 0, totalRecords: 0, settledTickets: 0, openTickets: 0,
      finesCharged: 0, finesSettled: 0, daysWithRecords: 0, lastRecordAt: null,
    }),
  ],
  // 1 + 2 + 0 = 3 warnings; 4 + 3 = 7 tickets; 10 records; 3 settled; 4 open; 5300.50 and 2800.
  totals: { warnings: 3, tickets: 7, totalRecords: 10, settledTickets: 3, openTickets: 4, finesCharged: 5300.5, finesSettled: 2800 },
};

test("period buttons pick today, the Philippine week from Monday, and the month so far", () => {
  // Fri 20 Nov 2026.
  assert.deepEqual({ ...utils.reportPeriodPreset("today", "2026-11-20") }, { from: "2026-11-20", to: "2026-11-20" });
  assert.deepEqual({ ...utils.reportPeriodPreset("week", "2026-11-20") }, { from: "2026-11-16", to: "2026-11-20" });
  assert.deepEqual({ ...utils.reportPeriodPreset("month", "2026-11-20") }, { from: "2026-11-01", to: "2026-11-20" });
  // Sunday still belongs to the week that started on Monday 16 Nov; Monday starts its own week.
  assert.equal(utils.reportPeriodPreset("week", "2026-11-22").from, "2026-11-16");
  assert.equal(utils.reportPeriodPreset("week", "2026-11-16").from, "2026-11-16");
  // Tue 1 Dec: the week began on Mon 30 Nov, in the month before.
  assert.equal(utils.reportPeriodPreset("week", "2026-12-01").from, "2026-11-30");
});

test("a period button shows as chosen only when the dates match it", () => {
  const today = "2026-11-20";
  assert.equal(utils.isPresetPeriod("month", { from: "2026-11-01", to: today }, today), true);
  assert.equal(utils.isPresetPeriod("week", { from: "2026-11-01", to: today }, today), false);
  assert.equal(utils.isPresetPeriod("month", { from: "2026-11-02", to: today }, today), false);
  // On the 1st, Today and This month are the same dates, so both show as chosen.
  const first = "2026-12-01";
  assert.equal(utils.isPresetPeriod("today", { from: first, to: first }, first), true);
  assert.equal(utils.isPresetPeriod("month", { from: first, to: first }, first), true);
});

test("bad dates get the same messages as the Reports page", () => {
  const today = "2026-11-20";
  assert.equal(utils.validateReportPeriod({ from: "2026-11-01", to: "2026-11-20" }, today), "");
  assert.equal(utils.validateReportPeriod({ from: "", to: "2026-11-20" }, today), "Choose a valid From and To date.");
  assert.equal(utils.validateReportPeriod({ from: "2026-02-30", to: "2026-11-20" }, today), "Choose a valid From and To date.");
  assert.equal(
    utils.validateReportPeriod({ from: "2026-11-10", to: "2026-11-09" }, today),
    "The To date must be on or after the From date.",
  );
  assert.equal(utils.validateReportPeriod({ from: "2026-11-01", to: "2026-11-21" }, today), "Choose dates on or before today.");
});

test("the CSV file has one line per enforcer, then the total line, with plain numbers", () => {
  const csv = toCsv(utils.ENFORCER_REPORT_COLUMNS, utils.enforcerReportLines(report));
  assert.deepEqual(csv.split("\r\n"), [
    '"Enforcer","Username","Status","Warnings","Tickets","Total records","Settled tickets","Open tickets","Fines charged (PHP)","Fines settled (PHP)","Days with records","Last record"',
    '"Dela Cruz, Juan","ENF-0008","Active","1","4","5","2","2","3000.00","2000.00","3","2026-11-05"',
    '"Santos, Mia","ENF-0011","Inactive","2","3","5","1","2","2300.50","800.00","2","2026-11-03"',
    '"Bautista, Leo","ENF-0010","Active","0","0","0","0","0","0.00","0.00","0",""',
    '"Total","","","3","7","10","3","4","5300.50","2800.00","",""',
  ]);
});

test("a name that looks like a spreadsheet formula is not run by Excel", () => {
  const unsafe = { ...report, enforcers: [row({ lastName: "=HYPERLINK(\"x\")", firstName: "A" })] };
  const csv = toCsv(utils.ENFORCER_REPORT_COLUMNS, utils.enforcerReportLines(unsafe));
  assert.match(csv.split("\r\n")[1], /^"'=HYPERLINK\(""x""\), A"/);
});

const idleModel = {
  today: "2026-11-20",
  period: { from: "2026-11-02", to: "2026-11-05" },
  validation: "",
  report,
  loading: false,
  error: "",
  paperRef: { current: null },
  retry() {},
  choosePreset() {},
  changeFrom() {},
  changeTo() {},
  print() {},
  exportCsv() {},
};

function renderReportPage(model = {}) {
  const { default: Page } = load("features/enforcers/pages/EnforcerReportPage.tsx", {
    "react-router-dom": { ...realRouter, useNavigate: () => () => {} },
    "@/features/enforcers/hooks/useEnforcerReport": { useEnforcerReport: () => ({ ...idleModel, ...model }) },
  });
  return renderToStaticMarkup(React.createElement(Page));
}

test("a loaded report shows every row, the total row, pesos and Philippine dates", () => {
  const html = renderReportPage();
  assert.match(html, /Dela Cruz, Juan/);
  assert.match(html, /ENF-0008/);
  assert.match(html, /₱3,000\.00/);
  assert.match(html, /₱2,300\.50/);
  assert.match(html, /₱5,300\.50/);
  // The last record is 5 Nov in the Philippines, not 4 Nov (UTC).
  assert.match(html, /Nov 5, 2026/);
  assert.doesNotMatch(html, /Nov 4, 2026/);
  // Only the inactive enforcer is marked inactive.
  assert.equal(html.match(/>Inactive</g)?.length, 1);
  assert.match(html, /Total<\/th>/);
  assert.match(html, /Nov 2, 2026 – Nov 5, 2026/);
  assert.doesNotMatch(html, /No warnings or tickets were recorded/);
});

test("a period with no records says so instead of showing an empty table only", () => {
  const empty = {
    ...report,
    enforcers: [report.enforcers[2]],
    totals: { warnings: 0, tickets: 0, totalRecords: 0, settledTickets: 0, openTickets: 0, finesCharged: 0, finesSettled: 0 },
  };
  const html = renderReportPage({ report: empty });
  assert.match(html, /No warnings or tickets were recorded in this period\./);
  assert.match(html, /Bautista, Leo/);
});

test("while loading, placeholder rows show and the download buttons are off", () => {
  const html = renderReportPage({ report: undefined, loading: true });
  assert.match(html, /aria-busy="true"/);
  assert.match(html, /Loading report/);
  assert.doesNotMatch(html, /Dela Cruz/);
  const downloads = [...html.matchAll(/<button([^>]*)>([^]*?)<\/button>/g)].filter(([, , text]) =>
    /Print|Export CSV/.test(text),
  );
  assert.equal(downloads.length, 2);
  assert.ok(downloads.every(([, attributes]) => /disabled=""/.test(attributes)));
});

test("a report that fails to load shows the server's message and Try again", () => {
  const html = renderReportPage({ report: undefined, error: "From must be on or before to." });
  assert.match(html, /role="alert"/);
  assert.match(html, /From must be on or before to\./);
  assert.match(html, /Try again/);
});

test("bad dates show their message by the date boxes and no report", () => {
  const html = renderReportPage({ report: undefined, validation: "Choose dates on or before today." });
  assert.match(html, /Choose dates on or before today\./);
  assert.match(html, /aria-invalid="true"/);
  assert.doesNotMatch(html, /Dela Cruz/);
});

function renderEnforcersPage(isAdmin) {
  const process = { isLoading: false, isFetching: false, isError: false, errorMessage: "", onRetry() {} };
  const { default: Page } = load("features/enforcers/pages/EnforcersPage.tsx", {
    "react-router-dom": { ...realRouter, useNavigate: () => () => {} },
    "@/context/AuthContext": { useAuth: () => ({ isAdmin }) },
    "@/features/enforcers/hooks/useEnforcerFilter": {
      useEnforcerFilter: () => ({
        filters: { search: "", statusFilter: "Active", sort: "Name" },
        setFilters: { setSearch() {}, setStatusFilter() {}, setSort() {} },
        sortOptions: { Name: {} },
        queryParams: {},
      }),
    },
    "@/features/enforcers/hooks/useFetchEnforcers": {
      useFetchEnforcers: () => ({
        enforcers: [], total: 0, totalPages: 1, page: 1, pageSize: 10, setPage() {}, fetchProcess: process,
      }),
    },
    "@/features/enforcers/hooks/useFetchActivity": {
      useFetchActivity: () => ({ averageWarning: 0, averageTicket: 0, topEnforcers: [], activityProcess: process }),
    },
  });
  return renderToStaticMarkup(React.createElement(Page));
}

test("only admins see the Enforcer report button on the Enforcers page", () => {
  assert.match(renderEnforcersPage(true), /Enforcer report/);
  assert.doesNotMatch(renderEnforcersPage(false), /Enforcer report/);
});
