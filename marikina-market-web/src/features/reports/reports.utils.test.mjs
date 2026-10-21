import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import ts from "typescript";

const source = await readFile(
  new URL("./reports.utils.ts", import.meta.url),
  "utf8",
);
const output = ts.transpileModule(source, {
  compilerOptions: {
    module: ts.ModuleKind.ESNext,
    target: ts.ScriptTarget.ES2020,
  },
}).outputText;
const {
  validateReportRange,
  reportPreset,
  reportSummaryRows,
  reportCsv,
  filterReports,
  manilaToday,
  formatReportDate,
} = await import(
  `data:text/javascript;base64,${Buffer.from(output).toString("base64")}`
);

const metric = (totalRecords, assessedPenalties) => ({
  totalRecords,
  assessedPenalties,
});
const report = {
  id: 1,
  type: "Warning & Ticket",
  dateRange: { from: "2026-10-01", to: "2026-10-12" },
  dateGenerated: "2026-10-12T05:00:00Z",
  generatedBy: { id: 7, name: "Juan Dela Cruz" },
  summary: {
    total: metric(7, 1200),
    resolved: metric(2, 700),
    pending: metric(2, 500),
    warningsIssued: metric(3, 0),
    ticketsIssued: metric(4, 1200),
  },
};

const errorSource = await readFile(
  new URL("../../utils/apiErrors.ts", import.meta.url),
  "utf8",
);
const errorOutput = ts
  .transpileModule(errorSource, {
    compilerOptions: { module: ts.ModuleKind.ESNext },
  })
  .outputText.replace(
    '"axios"',
    JSON.stringify(
      new URL("../../../node_modules/axios/index.js", import.meta.url).href,
    ),
  );
const errorModule = `data:text/javascript;base64,${Buffer.from(errorOutput).toString("base64")}`;
const validationSource = await readFile(
  new URL("../../api/endpoints/reports.validation.ts", import.meta.url),
  "utf8",
);
const validationOutput = ts
  .transpileModule(validationSource, {
    compilerOptions: { module: ts.ModuleKind.ESNext },
  })
  .outputText.replace('"@/utils/apiErrors"', JSON.stringify(errorModule));
const { validateReport, validateReportHistory } = await import(
  `data:text/javascript;base64,${Buffer.from(validationOutput).toString("base64")}`
);

test("report responses require valid metadata, dates and non-negative finite metrics", () => {
  assert.deepEqual(validateReport(report, true), report);
  assert.throws(() => validateReport({ ...report, generatedBy: null }, true));
  assert.throws(() =>
    validateReport(
      { ...report, dateRange: { from: "2026-02-30", to: "2026-10-12" } },
      true,
    ),
  );
  for (const invalid of [
    metric(-1, 0),
    metric(1, -1),
    metric(1, Infinity),
    metric(0.5, 0),
  ]) {
    assert.throws(() =>
      validateReport(
        { ...report, summary: { ...report.summary, total: invalid } },
        true,
      ),
    );
  }
});
test("preview strips saved metadata and single types require null unused metrics", () => {
  const result = validateReport(
    {
      ...report,
      id: undefined,
      generatedBy: null,
      dateRange: { from: "2026-10-12", to: "2026-10-12" },
    },
    false,
  );
  assert.throws(() => validateReport(report, false));
  assert.equal("id" in result, false);
  assert.equal("generatedBy" in result, false);
  assert.throws(() => validateReport({ ...report, type: "Warning" }, true));
  const warning = {
    ...report,
    type: "Warning",
    summary: {
      total: metric(3, 0),
      resolved: metric(0, 0),
      pending: metric(0, 0),
      warningsIssued: metric(3, 0),
      ticketsIssued: null,
    },
  };
  assert.deepEqual(validateReport(warning, true), warning);
  assert.throws(() =>
    validateReport(
      { ...warning, summary: { ...warning.summary, resolved: metric(1, 0) } },
      true,
    ),
  );
  const ticket = {
    ...report,
    type: "Ticket",
    summary: {
      total: metric(4, 1200),
      resolved: metric(2, 700),
      pending: metric(2, 500),
      warningsIssued: null,
      ticketsIssued: metric(4, 1200),
    },
  };
  assert.deepEqual(validateReport(ticket, true), ticket);
  assert.throws(() =>
    validateReport(
      {
        ...ticket,
        summary: { ...ticket.summary, warningsIssued: metric(0, 0) },
      },
      true,
    ),
  );
});
test("flat issuer metrics reject old nested shapes and malformed values", () => {
  for (const field of ["warningsIssued", "ticketsIssued"]) {
    for (const invalid of [
      undefined,
      metric(-1, 0),
      metric(1, -1),
      metric(1, Infinity),
      { total: metric(3, 0), resolved: metric(3, 0), pending: metric(0, 0) },
    ]) {
      assert.throws(() =>
        validateReport(
          { ...report, summary: { ...report.summary, [field]: invalid } },
          true,
        ),
      );
    }
  }
});
test("history rejects invalid paging and malformed records", () => {
  const { summary, ...item } = report;
  assert.equal(
    validateReportHistory({ items: [item], total: 1, hasMore: false }).items
      .length,
    1,
  );
  assert.throws(() =>
    validateReportHistory({ items: [], total: 12, hasMore: true }),
  );
  assert.throws(() =>
    validateReportHistory({
      items: Array.from({ length: 11 }, () => item),
      total: 11,
      hasMore: false,
    }),
  );
  assert.throws(() =>
    validateReportHistory({ items: [item], total: 0, hasMore: false }),
  );
  assert.throws(() =>
    validateReportHistory({
      items: [{ ...item, id: "1" }],
      total: 1,
      hasMore: false,
    }),
  );
});

test("date validation rejects impossible, missing, reversed, and future dates", () => {
  for (const [from, to] of [
    ["", "2026-10-12"],
    ["2026-02-30", "2026-10-12"],
    ["2026-10-12", "2026-10-01"],
    ["2026-10-01", "2026-10-13"],
  ]) {
    assert.ok(validateReportRange({ from, to, type: "Ticket" }, "2026-10-12"));
  }
  assert.equal(
    validateReportRange(
      { from: "2024-02-29", to: "2024-02-29", type: "Warning" },
      "2026-10-12",
    ),
    "",
  );
  assert.ok(
    validateReportRange(
      { from: "2026-10-01", to: "2026-10-12", type: "Unknown" },
      "2026-10-12",
    ),
  );
});
test("presets respect calendar boundaries and inclusive Manila dates", () => {
  assert.deepEqual(reportPreset("month", "2026-10-12"), {
    from: "2026-10-01",
    to: "2026-10-12",
  });
  assert.deepEqual(reportPreset("quarter", "2026-01-12"), {
    from: "2025-10-01",
    to: "2025-12-31",
  });
  assert.deepEqual(reportPreset("quarter", "2026-10-12"), {
    from: "2026-07-01",
    to: "2026-09-30",
  });
  assert.deepEqual(reportPreset("year", "2026-10-12"), {
    from: "2026-01-01",
    to: "2026-10-12",
  });
  assert.equal(manilaToday(new Date("2026-10-11T16:30:00Z")), "2026-10-12");
  assert.match(formatReportDate("2026-10-12"), /Oct 12, 2026/);
});
test("paper summary uses issue totals and saved resolution totals without duplicating records", () => {
  assert.deepEqual(reportSummaryRows(report), [
    { label: "Warnings issued", totalRecords: 3, assessedPenalties: 0 },
    { label: "Tickets issued", totalRecords: 4, assessedPenalties: 1200 },
    { label: "Resolved records", totalRecords: 2, assessedPenalties: 700 },
    { label: "Pending records", totalRecords: 2, assessedPenalties: 500 },
    { label: "Total", totalRecords: 7, assessedPenalties: 1200 },
  ]);
  assert.deepEqual(
    reportSummaryRows({
      ...report,
      type: "Warning",
      summary: { ...report.summary, ticketsIssued: null },
    }).map((row) => row.label),
    ["Warnings issued", "Resolved records", "Pending records", "Total"],
  );
});
test("CSV exports the flat API summary and protects spreadsheet formulas", () => {
  const csv = reportCsv({
    ...report,
    generatedBy: { id: 7, name: '=HYPERLINK("https://example.com")' },
  });
  assert.ok(csv.startsWith("\uFEFF"));
  assert.match(csv, /"Total","7","1200"/);
  assert.match(csv, /"Tickets issued","4","1200"/);
  assert.match(csv, /"Resolved records","2","700"/);
  assert.equal(csv.includes("undefined"), false);
  assert.match(csv, /'=/);
  assert.match(csv, /"2026-10-01"/);
});
test("history search combines report type, dates, generator, and ID", () => {
  assert.equal(filterReports([report], "juan", "all").length, 1);
  assert.equal(
    filterReports([report], "2026-10-01", "Warning & Ticket").length,
    1,
  );
  assert.equal(filterReports([report], "", "Ticket").length, 0);
  assert.equal(filterReports([report], "missing", "all").length, 0);
});

test("Warning summary and CSV hide tickets and preserve zero resolution metrics", () => {
  const warning = {
    ...report,
    type: "Warning",
    summary: {
      total: metric(3, 0),
      resolved: metric(0, 0),
      pending: metric(0, 0),
      warningsIssued: metric(3, 0),
      ticketsIssued: null,
    },
  };
  assert.deepEqual(reportSummaryRows(warning), [
    { label: "Warnings issued", totalRecords: 3, assessedPenalties: 0 },
    { label: "Resolved records", totalRecords: 0, assessedPenalties: 0 },
    { label: "Pending records", totalRecords: 0, assessedPenalties: 0 },
    { label: "Total", totalRecords: 3, assessedPenalties: 0 },
  ]);
  const csv = reportCsv(warning);
  assert.equal(csv.includes("Tickets issued"), false);
  assert.match(csv, /"Resolved records","0","0"/);
  const ticket = {
    ...report,
    type: "Ticket",
    summary: { ...report.summary, warningsIssued: null },
  };
  assert.equal(
    reportSummaryRows(ticket).some((row) => row.label === "Warnings issued"),
    false,
  );
  assert.equal(reportCsv(ticket).includes("Warnings issued"), false);
});
