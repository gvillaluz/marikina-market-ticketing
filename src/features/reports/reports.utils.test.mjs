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
  reportRows,
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
  dateGenerated: "2026-10-12T01:00:00Z",
  generatedBy: { id: 7, name: "Juan Dela Cruz" },
  summary: {
    total: metric(7, 1200),
    resolved: metric(5, 700),
    pending: metric(2, 500),
    warningsIssued: {
      total: metric(3, 0),
      resolved: metric(3, 0),
      pending: metric(0, 0),
    },
    ticketsIssued: {
      total: metric(4, 1200),
      resolved: metric(2, 700),
      pending: metric(2, 500),
    },
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
test("preview strips saved metadata and single types require null unused breakdowns", () => {
  const result = validateReport(
    { ...report, id: undefined, generatedBy: null },
    false,
  );
  assert.equal("id" in result, false);
  assert.equal("generatedBy" in result, false);
  assert.throws(() => validateReport({ ...report, type: "Warning" }, true));
  assert.equal(
    validateReport(
      {
        ...report,
        type: "Warning",
        summary: { ...report.summary, ticketsIssued: null },
      },
      true,
    ).type,
    "Warning",
  );
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
test("summary rows preserve saved totals and both type breakdowns", () => {
  const rows = reportRows(report);
  assert.equal(rows.length, 9);
  assert.deepEqual(rows[0], { label: "Resolved records", ...metric(5, 700) });
  assert.deepEqual(rows[2], { label: "Total", ...metric(7, 1200) });
  assert.deepEqual(rows[8], {
    label: "Tickets issued — total",
    ...metric(4, 1200),
  });
  assert.equal(
    reportRows({
      ...report,
      type: "Warning",
      summary: { ...report.summary, ticketsIssued: null },
    }).length,
    6,
  );
});
test("CSV includes complete numeric breakdowns and protects spreadsheet formulas", () => {
  const csv = reportCsv({
    ...report,
    generatedBy: { id: 7, name: '=HYPERLINK("https://example.com")' },
  });
  assert.ok(csv.startsWith("\uFEFF"));
  assert.match(csv, /"Total","7","1200"/);
  assert.match(csv, /"Tickets issued — pending","2","500"/);
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
