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

// The report for one enforcer. The data hook is replaced with fixed answers so each case can be drawn;
// everything the page draws is the real code. Every expected value is worked out by hand.

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

// Records 1-8 of the server test: 2 warnings and 6 tickets over 2-4 Nov.
const counts = (warnings, tickets) => ({ warnings, tickets, total: warnings + tickets });
const report = {
  dateRange: { from: "2026-11-02", to: "2026-11-05" },
  enforcer: {
    enforcerId: 8, username: "ENF-0008", firstName: "Juan", lastName: "Dela Cruz", status: "Active",
    warnings: 2, tickets: 6, totalRecords: 8, settledTickets: 3, openTickets: 3,
    finesCharged: 2500, finesSettled: 1500, daysWithRecords: 3,
    // Wed 4 Nov 23:30 in the Philippines.
    lastRecordAt: "2026-11-04T15:30:00Z",
  },
  penaltyKinds: [
    { penaltyType: "CashFine", tickets: 2, settledTickets: 1, openTickets: 1, finesCharged: 2500 },
    { penaltyType: "CommunityService", tickets: 2, settledTickets: 1, openTickets: 1, finesCharged: 0 },
    { penaltyType: "BloodDonation", tickets: 1, settledTickets: 1, openTickets: 0, finesCharged: 0 },
    { penaltyType: null, tickets: 1, settledTickets: 0, openTickets: 1, finesCharged: 0 },
  ],
  violationTypes: [
    { category: "Sanitation", ...counts(0, 3) },
    { category: "Obstruction", ...counts(1, 1) },
    { category: "Licensing", ...counts(0, 2) },
    { category: null, ...counts(1, 1) },
  ],
  marketStreets: [
    { marketSectionId: 1, marketSectionName: "Dry Goods Lane", ...counts(1, 4) },
    { marketSectionId: 2, marketSectionName: "Wet Market Row", ...counts(1, 2) },
  ],
  days: [
    { date: "2026-11-02", ...counts(0, 2) },
    { date: "2026-11-03", ...counts(1, 2) },
    { date: "2026-11-04", ...counts(1, 2) },
  ],
};

test("share of records is rounded to a whole percent", () => {
  // 3 of 8 = 37.5% -> 38; 5 of 8 = 62.5% -> 63; 2 of 8 = 25; nothing recorded -> 0.
  assert.equal(utils.sharePercent(3, 8), 38);
  assert.equal(utils.sharePercent(5, 8), 63);
  assert.equal(utils.sharePercent(2, 8), 25);
  assert.equal(utils.sharePercent(0, 0), 0);
});

test("labels use the website's wording, with Not recorded for a missing value", () => {
  assert.equal(utils.penaltyKindLabel("CashFine"), "Cash fine");
  assert.equal(utils.penaltyKindLabel("BloodDonation"), "Blood donation");
  assert.equal(utils.penaltyKindLabel("CommunityService"), "Community service");
  assert.equal(utils.penaltyKindLabel(null), "Not recorded");
  assert.equal(utils.violationTypeLabel("WeightMeasures"), "Weights & Measures");
  assert.equal(utils.violationTypeLabel("NonSmoking"), "Non-Smoking");
  assert.equal(utils.violationTypeLabel("Licensing"), "Licensing");
  assert.equal(utils.violationTypeLabel(null), "Not recorded");
});

test("the chart has one bar per day, including days with no records", () => {
  const chart = utils.chartBars(report.days, report.dateRange);
  assert.equal(chart.unit, "day");
  assert.deepEqual(Array.from(chart.bars, (bar) => [bar.from, bar.total]), [
    ["2026-11-02", 2],
    ["2026-11-03", 3],
    ["2026-11-04", 3],
    ["2026-11-05", 0],
  ]);
});

test("up to 62 days the chart stays daily; longer periods get one bar per Monday week", () => {
  // 20 Sep - 20 Nov is 11 + 31 + 20 = 62 days.
  assert.equal(utils.chartBars([], { from: "2026-09-20", to: "2026-11-20" }).bars.length, 62);
  // 1 Sep (a Tuesday) - 20 Nov is 81 days: weeks starting Mon 31 Aug ... Mon 16 Nov = 12 bars.
  const days = [
    { date: "2026-09-01", ...counts(1, 0) },
    { date: "2026-11-16", ...counts(0, 1) },
    { date: "2026-11-18", ...counts(0, 2) },
  ];
  const chart = utils.chartBars(days, { from: "2026-09-01", to: "2026-11-20" });
  assert.equal(chart.unit, "week");
  assert.equal(chart.bars.length, 12);
  // The first bar starts at the period's first day, not the Monday before it.
  assert.deepEqual([chart.bars[0].from, chart.bars[0].total], ["2026-09-01", 1]);
  assert.deepEqual([chart.bars[11].from, chart.bars[11].total], ["2026-11-16", 3]);
  assert.equal(chart.bars.slice(1, 11).every((bar) => bar.total === 0), true);
  // One day more than 62 also switches to weeks.
  assert.equal(utils.chartBars([], { from: "2026-09-19", to: "2026-11-20" }).unit, "week");
});

test("the CSV has every table, one after another, each under its title", () => {
  assert.deepEqual(utils.enforcerActivityCsv(report).split("\r\n"), [
    '"Enforcer","Dela Cruz, Juan"',
    '"Username","ENF-0008"',
    '"From","2026-11-02"',
    '"To","2026-11-05"',
    "",
    '"Summary"',
    '"Warnings","Tickets","Total records","Settled tickets","Open tickets","Fines charged (PHP)","Fines settled (PHP)","Days with records","Last record"',
    '"2","6","8","3","3","2500.00","1500.00","3","2026-11-04"',
    "",
    '"Penalty kind"',
    '"Penalty kind","Tickets","Settled tickets","Open tickets","Fines charged (PHP)"',
    '"Cash fine","2","1","1","2500.00"',
    '"Community service","2","1","1","0.00"',
    '"Blood donation","1","1","0","0.00"',
    '"Not recorded","1","0","1","0.00"',
    "",
    '"Violation type"',
    '"Violation type","Warnings","Tickets","Total","Share of records (%)"',
    '"Sanitation","0","3","3","38"',
    '"Obstruction","1","1","2","25"',
    '"Licensing","0","2","2","25"',
    '"Not recorded","1","1","2","25"',
    "",
    '"Market street"',
    '"Market street","Warnings","Tickets","Total","Share of records (%)"',
    '"Dry Goods Lane","1","4","5","63"',
    '"Wet Market Row","1","2","3","38"',
    "",
    '"Records per day"',
    '"Date","Warnings","Tickets","Total"',
    '"2026-11-02","0","2","2"',
    '"2026-11-03","1","2","3"',
    '"2026-11-04","1","2","3"',
  ]);
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

function renderPage(model = {}, id = "8") {
  const { default: Page } = load("features/enforcers/pages/EnforcerActivityReportPage.tsx", {
    "@/assets/icons/Marikina_City_Seal.svg (1).webp": { default: "seal.webp" },
    "react-router-dom": { ...realRouter, useParams: () => ({ id }), useNavigate: () => () => {} },
    "@/features/enforcers/hooks/useEnforcerActivityReport": {
      useEnforcerActivityReport: () => ({ ...idleModel, ...model }),
    },
  });
  // The breadcrumb's links need a router around the page.
  return renderToStaticMarkup(
    React.createElement(realRouter.MemoryRouter, null, React.createElement(Page)),
  );
}
const text = (html) => html.replace(/<[^>]+>/g, " ").replace(/&amp;/g, "&").replace(/&#x27;/g, "'").replace(/\s+/g, " ");

test("the summary tiles show the enforcer's numbers, pesos and the Philippine date", () => {
  const html = text(renderPage());
  assert.match(html, /Dela Cruz, Juan/);
  assert.match(html, /ENF-0008/);
  assert.match(html, /Warnings 2 /);
  assert.match(html, /Tickets 6 /);
  assert.match(html, /Total records 8 /);
  assert.match(html, /Fines charged ₱2,500\.00/);
  assert.match(html, /Fines settled ₱1,500\.00/);
  assert.match(html, /Last record Nov 4, 2026/);
  assert.match(html, /Nov 2, 2026 – Nov 5, 2026/);
});

test("the penalty kind table shows pesos only where a fine was charged", () => {
  const html = text(renderPage());
  assert.match(html, /Cash fine 2 1 1 ₱2,500\.00/);
  assert.match(html, /Community service 2 1 1 —/);
  assert.match(html, /Blood donation 1 1 0 —/);
  assert.match(html, /Not recorded 1 0 1 —/);
});

test("violation types and streets show their share of all records", () => {
  const html = text(renderPage());
  assert.match(html, /Sanitation 0 3 3 38%/);
  assert.match(html, /Not recorded 1 1 2 25%/);
  assert.match(html, /Dry Goods Lane 1 4 5 63%/);
  assert.match(html, /Wet Market Row 1 2 3 38%/);
  assert.match(html, /A record with more than one violation type is counted under each\./);
});

test("the chart has a bar for every day and the table lists the days with records", () => {
  const html = renderPage();
  assert.equal(html.match(/data-bar=/g)?.length, 4);
  assert.match(html, /title="Nov 5, 2026: 0 records"/);
  assert.match(html, /title="Nov 3, 2026: 3 records"/);
  assert.match(text(html), /Nov 3, 2026 1 2 3/);
});

test("a period with no records says so and leaves out the empty tables and chart", () => {
  const empty = {
    ...report,
    enforcer: { ...report.enforcer, warnings: 0, tickets: 0, totalRecords: 0, settledTickets: 0, openTickets: 0,
      finesCharged: 0, finesSettled: 0, daysWithRecords: 0, lastRecordAt: null },
    penaltyKinds: [], violationTypes: [], marketStreets: [], days: [],
  };
  const html = renderPage({ report: empty });
  assert.match(html, /No warnings or tickets were recorded in this period\./);
  assert.doesNotMatch(html, /Penalty kind/);
  assert.doesNotMatch(html, /data-bar=/);
  assert.match(text(html), /Last record —/);
});

test("loading, failure and bad dates each show their state", () => {
  const loading = renderPage({ report: undefined, loading: true });
  assert.match(loading, /aria-busy="true"/);
  assert.match(loading, /Loading report/);
  const failed = renderPage({ report: undefined, error: "Enforcer not found." });
  assert.match(failed, /role="alert"/);
  assert.match(failed, /Enforcer not found\./);
  assert.match(failed, /Try again/);
  const bad = renderPage({ report: undefined, validation: "Choose dates on or before today." });
  assert.match(bad, /Choose dates on or before today\./);
  assert.doesNotMatch(bad, /Dela Cruz/);
});

test("a link that is not an enforcer number says so without asking the server", () => {
  for (const id of ["abc", "0", "-3", "1.5"]) {
    const html = renderPage({}, id);
    assert.match(html, /Enforcer not found/, id);
    assert.doesNotMatch(html, /Dela Cruz/, id);
  }
});

test("a breadcrumb leads to the Enforcers list and to this enforcer's performance record", () => {
  const html = renderPage();
  assert.match(html, /<nav[^>]*aria-label="Breadcrumb"/);
  assert.match(html, /<a [^>]*href="\/enforcers"[^>]*>Enforcers<\/a>/);
  assert.match(html, /<a [^>]*href="\/enforcer\/performance\/8"[^>]*>Dela Cruz, Juan<\/a>/);
  assert.match(html, /aria-current="page"[^>]*>Enforcer report</);
  // The button stays next to the trail.
  assert.match(html, /Back to performance record/);
  // While the report loads or after it fails, the trail still leads back.
  for (const model of [{ report: undefined, loading: true }, { report: undefined, error: "Enforcer not found." }]) {
    const waiting = renderPage(model);
    assert.match(waiting, /href="\/enforcers"/);
    assert.match(waiting, /<a [^>]*href="\/enforcer\/performance\/8"[^>]*>Enforcer<\/a>/);
  }
});

test("a link that is not an enforcer number still leads back to the Enforcers list", () => {
  const html = renderPage({}, "abc");
  assert.match(html, /<a [^>]*href="\/enforcers"[^>]*>Enforcers<\/a>/);
  assert.match(html, /aria-current="page"[^>]*>Enforcer report</);
  assert.doesNotMatch(html, /\/enforcer\/performance\//);
});

test("the report's address carries the enforcer number", () => {
  const { ROUTES } = load("routes/routePaths.ts");
  assert.equal(ROUTES.enforcerActivityReport("8"), "/enforcers/report/8");
});
