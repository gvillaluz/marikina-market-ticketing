import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import ts from "typescript";

async function compile(relativePath, replacements = {}) {
  const source = await readFile(new URL(relativePath, import.meta.url), "utf8");
  let output = ts.transpileModule(source, {
    compilerOptions: {
      module: ts.ModuleKind.ESNext,
      target: ts.ScriptTarget.ES2020,
    },
  }).outputText;
  for (const [from, to] of Object.entries(replacements))
    output = output.replaceAll(JSON.stringify(from), JSON.stringify(to));
  return `data:text/javascript;base64,${Buffer.from(output).toString("base64")}`;
}

const { auditQuery } = await import(
  await compile("../../api/endpoints/audit.query.ts")
);
const { auditActionLabel, auditActorName, auditCsv, formatAuditTimestamp } =
  await import(await compile("./audit.utils.ts"));
const roles = await compile("../../api/types/common.types.ts");
const constants = await compile("./audit.constants.ts");
const errors = await compile("../../utils/apiErrors.ts", {
  axios: new URL("../../../node_modules/axios/index.js", import.meta.url).href,
});
const { validateAuditPage, validateAuditCounts, validateAuditDetail } =
  await import(
    await compile("./audit.validation.ts", {
      "@/api/types/common.types": roles,
      "@/utils/apiErrors": errors,
      "./audit.constants": constants,
    })
  );
const record = {
  id: 101,
  timestamp: "2026-10-10T04:12:00Z",
  userId: 7,
  firstName: "Juan",
  lastName: "Dela Cruz",
  role: "HeadAdmin",
  action: "EditUserInformation",
  module: "Users",
  result: "Success",
};

test("All omits list filters and AllTime omits a date restriction", () => {
  assert.equal(
    auditQuery({ modules: [], results: [], dateRange: "AllTime" }, 0),
    "?offset=0",
  );
  assert.equal(auditQuery({}), "");
});
test("actor names use both names, support partial names, and fall back to System or user ID", () => {
  assert.equal(auditActorName(record), "Juan Dela Cruz");
  assert.equal(
    auditActorName({ ...record, firstName: " Juan ", lastName: null }),
    "Juan",
  );
  assert.equal(
    auditActorName({ userId: null, firstName: null, lastName: null }),
    "System",
  );
  assert.equal(
    auditActorName({ userId: 7, firstName: null, lastName: null }),
    "User #7",
  );
});
test("summary and detail validation accept null names and reject non-text names", () => {
  const system = {
    ...record,
    userId: null,
    firstName: null,
    lastName: null,
    role: null,
  };
  assert.equal(
    validateAuditPage({ items: [system], total: 1, hasMore: false }).items[0]
      .firstName,
    null,
  );
  assert.equal(
    validateAuditDetail({ ...system, targetId: null, details: null }, 101)
      .lastName,
    null,
  );
  assert.throws(() =>
    validateAuditPage({
      items: [{ ...record, firstName: 7 }],
      total: 1,
      hasMore: false,
    }),
  );
});
test("modules and results are repeated, stable, deduplicated camelCase query keys", () => {
  const query = new URLSearchParams(
    auditQuery(
      {
        modules: ["Users", "Security", "Users"],
        results: ["Success", "Failed"],
        dateRange: "Last7Days",
      },
      10,
    ).slice(1),
  );
  assert.deepEqual(query.getAll("modules"), ["Security", "Users"]);
  assert.deepEqual(query.getAll("results"), ["Failed", "Success"]);
  assert.equal(query.get("dateRange"), "Last7Days");
  assert.equal(query.has("date_range"), false);
  assert.equal(query.has("module"), false);
  assert.equal(query.has("result"), false);
});
test("table and count filters match exactly, with offset only on table requests", () => {
  const filters = {
    modules: ["Users"],
    results: ["Success"],
    dateRange: "Yesterday",
    search: "password",
    userId: 7,
    role: "HeadAdmin",
  };
  const table = new URLSearchParams(auditQuery(filters, 20).slice(1));
  table.delete("offset");
  assert.equal(table.toString(), auditQuery(filters).slice(1));
  assert.equal(table.get("userId"), "7");
  assert.equal(table.has("user_id"), false);
});
test("search values are encoded and cannot inject query parameters", () => {
  const query = new URLSearchParams(
    auditQuery({ search: " password&role=HeadAdmin " }).slice(1),
  );
  assert.equal(query.get("search"), "password&role=HeadAdmin");
  assert.equal(query.has("role"), false);
});
test("all seven date presets serialize without explicit dates", () => {
  for (const dateRange of [
    "AllTime",
    "Today",
    "Yesterday",
    "Last7Days",
    "Last30Days",
    "ThisMonth",
    "LastMonth",
  ]) {
    const query = new URLSearchParams(
      auditQuery({
        dateRange,
        fromDate: "2026-01-01",
        toDate: "2026-10-10",
      }).slice(1),
    );
    assert.equal(
      query.get("dateRange"),
      dateRange === "AllTime" ? null : dateRange,
    );
    assert.equal(query.has("fromDate"), false);
    assert.equal(query.has("toDate"), false);
  }
});
test("invalid offsets and user IDs are rejected before requests", () => {
  for (const offset of [-10, 1, 9, Infinity])
    assert.throws(() => auditQuery({}, offset), RangeError);
  assert.throws(() => auditQuery({ userId: 0 }), RangeError);
});
test("page validation accepts null actors and rejects malformed paging or records", () => {
  assert.equal(
    validateAuditPage({
      items: [{ ...record, userId: null, role: null }],
      total: 1,
      hasMore: false,
    }).items.length,
    1,
  );
  assert.throws(() =>
    validateAuditPage({ items: [record], total: 1, hasMore: true }),
  );
  assert.throws(() =>
    validateAuditPage({
      items: [{ ...record, result: "Unknown" }],
      total: 1,
      hasMore: false,
    }),
  );
});
test("counts include successful and failed security events and validate totals", () => {
  assert.deepEqual(
    validateAuditCounts({
      recordedActivities: 2,
      successfulActions: 1,
      securityEvents: 2,
    }),
    { recordedActivities: 2, successfulActions: 1, securityEvents: 2 },
  );
  assert.throws(() =>
    validateAuditCounts({
      recordedActivities: 1,
      successfulActions: 2,
      securityEvents: 0,
    }),
  );
});
test("details validate the requested ID and nullable metadata", () => {
  assert.equal(
    validateAuditDetail({ ...record, targetId: null, details: null }, 101).id,
    101,
  );
  assert.throws(() =>
    validateAuditDetail({ ...record, targetId: "7", details: "Updated" }, 102),
  );
});
test("timestamps render in Asia/Manila and action labels remain plain text", () => {
  assert.ok(formatAuditTimestamp(record.timestamp).includes("12:12 PM"));
  assert.equal(
    auditActionLabel("EditUserInformation"),
    "Edit User Information",
  );
  assert.equal(auditActionLabel("APIKeyChanged"), "API Key Changed");
});
test("CSV escapes quotes and neutralizes spreadsheet formulas", () => {
  const csv = auditCsv([
    {
      ...record,
      action: '=HYPERLINK("bad")',
      userId: null,
      role: null,
      firstName: null,
      lastName: null,
    },
  ]);
  assert.ok(csv.includes('"\'=HYPERLINK(""bad"")"'));
  assert.ok(csv.includes(',"","",'));
});
test("CSV includes the names returned by the API", () => {
  const csv = auditCsv([record]);
  assert.ok(csv.includes('"First name","Last name"'));
  assert.ok(csv.includes('"Juan","Dela Cruz"'));
});
