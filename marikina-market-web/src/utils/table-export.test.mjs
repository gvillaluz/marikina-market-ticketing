import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";
import test from "node:test";
import vm from "node:vm";
import React from "react";
import { renderToStaticMarkup } from "react-dom/server";
import ts from "typescript";

const require = createRequire(import.meta.url);
const root = path.resolve(
  path.dirname(new URL(import.meta.url).pathname.replace(/^\/(\w:)/, "$1")),
  "..",
);

function load(relative, overrides = {}, globals = {}, cache = new Map()) {
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
      Error,
      Date,
      Intl,
      ...globals,
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
        const resolved = [
          base,
          `${base}.ts`,
          `${base}.tsx`,
          `${base}/index.ts`,
          `${base}/index.tsx`,
        ].find((p) => fs.existsSync(p) && fs.statSync(p).isFile());
        assert.ok(resolved, `Cannot resolve ${id}`);
        return load(path.relative(root, resolved), overrides, globals, cache);
      },
    },
    { filename: file },
  );
  return module.exports;
}

// Captures what a download would save, instead of touching a real browser.
function downloads() {
  const files = [];
  return {
    files,
    globals: {
      Blob: class {
        constructor(parts) {
          files.push({ text: parts.join("") });
        }
      },
      URL: { createObjectURL: () => "blob:export", revokeObjectURL() {} },
      document: {
        body: { appendChild() {} },
        createElement() {
          return {
            click() {},
            remove() {},
            set download(name) {
              files.at(-1).name = name;
            },
          };
        },
      },
      window: { setTimeout() {} },
    },
  };
}

// Runs a hook outside React: state lives in arrays, render() reruns the hook.
function runHook(file, name, extraOverrides = {}) {
  const states = [],
    refs = [],
    toasts = [],
    printed = [];
  let stateCursor = 0,
    refCursor = 0,
    printOptions;
  const saved = downloads();
  const mod = load(
    file,
    {
      react: {
        useRef(initial) {
          const i = refCursor++;
          return (refs[i] ??= { current: initial });
        },
        useState(initial) {
          const i = stateCursor++;
          if (!(i in states))
            states[i] = typeof initial === "function" ? initial() : initial;
          return [
            states[i],
            (value) => {
              states[i] = typeof value === "function" ? value(states[i]) : value;
            },
          ];
        },
      },
      "react-dom": { flushSync: (update) => update() },
      "react-to-print": {
        useReactToPrint(options) {
          printOptions = options;
          return () => printed.push(options.documentTitle);
        },
      },
      "@/components/ui/Toast/useToast": {
        useToast: () => ({ showToast: (toast) => toasts.push(toast) }),
      },
      ...extraOverrides,
    },
    saved.globals,
  );
  return {
    toasts,
    printed,
    files: saved.files,
    afterPrint: () => printOptions.onAfterPrint(),
    render(...args) {
      stateCursor = refCursor = 0;
      return mod[name](...args);
    },
  };
}

// A list of `total` numbered rows, served 10 at a time like the server.
function pagedList(total, make = (n) => ({ id: n })) {
  const offsets = [];
  return {
    offsets,
    fetchPage: async (offset) => {
      offsets.push(offset);
      const items = [];
      for (let n = offset; n < Math.min(offset + 10, total); n++)
        items.push(make(n));
      return { items, hasMore: offset + 10 < total };
    },
  };
}

const { fetchAllRows, toCsv, manilaDay } = load("utils/tableExport.ts");
// Values made inside the test sandbox are compared as plain copies.
const plain = (value) => JSON.parse(JSON.stringify(value));
// What a browser request failure looks like (an axios network error).
const networkError = () => Object.assign(new Error("Network Error"), { isAxiosError: true });
const idColumns = [{ key: "id", header: "Number", value: (row) => String(row.id) }];

test("all rows are collected until the server says there are no more", async () => {
  const list = pagedList(23);
  const rows = await fetchAllRows(list.fetchPage);
  assert.equal(rows.length, 23);
  assert.deepEqual(list.offsets, [0, 10, 20]);
  assert.deepEqual(plain(rows.map((row) => row.id)), [...Array(23).keys()]);
});

test("collecting stops on an empty page even if the server says there are more", async () => {
  let calls = 0;
  const rows = await fetchAllRows(async () => {
    calls++;
    return { items: [], hasMore: true };
  });
  assert.equal(rows.length, 0);
  assert.equal(calls, 1);
});

test("spreadsheet cells keep commas and quotes, and formula-like text is not run", () => {
  const columns = [
    { key: "name", header: "Name", value: (row) => row.name },
    { key: "note", header: "Note", value: (row) => row.note },
  ];
  const csv = toCsv(columns, [
    { name: "Dela Cruz, Juan", note: 'Said "later"' },
    { name: "=SUM(A1)", note: "+639171234567" },
    { name: "@cmd", note: "-5" },
  ]);
  assert.deepEqual(csv.split("\r\n"), [
    '"Name","Note"',
    '"Dela Cruz, Juan","Said ""later"""',
    `"'=SUM(A1)","'+639171234567"`,
    `"'@cmd","'-5"`,
  ]);
});

test("issue days are counted in Philippine time", () => {
  assert.equal(manilaDay("2026-11-14T15:59:00Z"), "2026-11-14");
  assert.equal(manilaDay("2026-11-14T16:00:00Z"), "2026-11-15");
  assert.equal(manilaDay("not a date"), "");
});

test("Export collects every page, downloads only the table, and confirms", async () => {
  const list = pagedList(12);
  const h = runHook("hooks/useTableExport.ts", "useTableExport");
  const options = { title: "Rows", fileName: "rows.csv", columns: idColumns, fetchPage: list.fetchPage };
  const running = h.render(options).exportFile();
  assert.equal(h.render(options).preparing, "export");
  await h.render(options).exportFile(); // a second press while busy does nothing
  await running;
  assert.deepEqual(list.offsets, [0, 10]);
  assert.equal(h.files.length, 1);
  assert.equal(h.files[0].name, "rows.csv");
  const lines = h.files[0].text.split("\r\n");
  assert.equal(lines[0], '﻿"Number"');
  assert.equal(lines.length, 13);
  assert.equal(h.toasts.at(-1).variant, "success");
  assert.equal(h.render(options).preparing, null);
});

test("Export and Print with no matching rows download and print nothing", async () => {
  const h = runHook("hooks/useTableExport.ts", "useTableExport");
  const options = { title: "Rows", fileName: "rows.csv", columns: idColumns, fetchPage: pagedList(0).fetchPage };
  await h.render(options).exportFile();
  await h.render(options).print();
  assert.equal(h.files.length, 0);
  assert.equal(h.printed.length, 0);
  assert.deepEqual(h.toasts.map((t) => t.variant), ["info", "info"]);
  assert.equal(h.toasts[0].description, "No records match the current search and filters.");
});

test("a loading failure shows an error and downloads or prints nothing", async () => {
  const h = runHook("hooks/useTableExport.ts", "useTableExport");
  const options = {
    title: "Rows", fileName: "rows.csv", columns: idColumns,
    fetchPage: async (offset) => {
      if (offset > 0) throw networkError();
      return { items: Array.from({ length: 10 }, (_, id) => ({ id })), hasMore: true };
    },
  };
  await h.render(options).exportFile();
  await h.render(options).print();
  assert.equal(h.files.length, 0);
  assert.equal(h.printed.length, 0);
  assert.deepEqual(h.toasts.map((t) => [t.title, t.variant]), [["Export failed", "error"], ["Print failed", "error"]]);
  assert.equal(h.toasts[0].description, "Couldn't load the records. Please try again.");
  assert.equal(h.render(options).preparing, null);
});

test("Print fills the print table with every row, opens printing once, then clears", async () => {
  const h = runHook("hooks/useTableExport.ts", "useTableExport");
  const options = { title: "Ticket records", fileName: "t.csv", columns: idColumns, fetchPage: pagedList(15).fetchPage };
  await h.render(options).print();
  assert.deepEqual(h.printed, ["Ticket records"]);
  const table = h.render(options).printTable;
  assert.equal(table.rows.length, 15);
  assert.equal(table.title, "Ticket records");
  assert.equal(h.files.length, 0);
  h.afterPrint();
  assert.equal(h.render(options).printTable.rows, null);
});

test("the print table shows only a title, headers and rows", () => {
  const { PrintTable } = load("components/ui/PrintTable/PrintTable.tsx");
  const columns = [
    { key: "name", header: "Business name", value: (row) => row.name },
    { key: "owner", header: "Registered owner", value: (row) => row.owner },
  ];
  const html = renderToStaticMarkup(React.createElement(PrintTable, {
    contentRef: { current: null }, title: "Business registry", columns,
    rows: [{ name: "Nena Fresh Fish", owner: "Nena Dela Cruz" }],
  }));
  const text = (part) => [...html.matchAll(new RegExp(`<${part}(?: [^>]*)?>(.*?)</${part}>`, "g"))].map((m) => m[1]);
  assert.deepEqual(text("h1"), ["Business registry"]);
  assert.deepEqual(text("th"), ["Business name", "Registered owner"]);
  assert.deepEqual(text("td"), ["Nena Fresh Fish", "Nena Dela Cruz"]);
  assert.ok(!/<button|<input|<nav/.test(html), "no buttons, filters or page numbers");
  assert.equal(renderToStaticMarkup(React.createElement(PrintTable, {
    contentRef: { current: null }, title: "Empty", columns, rows: null,
  })), "");
});

// Rows for the export form: two warnings and two tickets on known Manila days.
const formRows = [
  { id: 1, type: "Warning", issuedAt: "2026-11-09T16:30:00Z" }, // Nov 10 in Manila
  { id: 2, type: "Ticket", issuedAt: "2026-11-10T03:00:00Z" }, // Nov 10
  { id: 3, type: "Ticket", issuedAt: "2026-11-12T15:59:00Z" }, // Nov 12, last minute
  { id: 4, type: "Warning", issuedAt: "2026-11-12T16:00:00Z" }, // Nov 13
];
const formColumns = [
  { key: "id", header: "Number", value: (row) => String(row.id) },
  { key: "type", header: "Type", value: (row) => row.type },
  { key: "issuedAt", header: "Issued at", value: (row) => row.issuedAt },
];
function formHarness(extra = {}) {
  const requests = [];
  let exported = 0;
  const h = runHook("features/inspections/hooks/usePrintConfigForm.ts", "usePrintConfigForm");
  const options = {
    fileName: "inspection-records.csv",
    columns: formColumns,
    recordTypes: ["Warning", "Ticket"],
    fetchPage: async (offset, type) => {
      requests.push({ offset, type });
      return { items: formRows.filter((row) => !type || row.type === type), hasMore: false };
    },
    onExported: () => exported++,
    ...extra,
  };
  return { ...h, requests, options, exported: () => exported, form: () => h.render(options) };
}
const downloadedIds = (file) => file.text.replace("﻿", "").split("\r\n").slice(1).map((line) => line.split(",")[0]);

test("export form: both record types ask for all records; one type asks only for that type", async () => {
  const h = formHarness();
  await h.form().handleGenerate();
  assert.deepEqual(h.requests.at(-1), { offset: 0, type: undefined });
  assert.deepEqual(downloadedIds(h.files[0]), ['"1"', '"2"', '"3"', '"4"']);
  h.form().toggleType("Warning");
  await h.form().handleGenerate();
  assert.deepEqual(h.requests.at(-1), { offset: 0, type: "Ticket" });
  assert.deepEqual(downloadedIds(h.files[1]), ['"2"', '"3"']);
  assert.equal(h.exported(), 2);
  assert.equal(h.toasts.at(-1).variant, "success");
});

test("export form: the date range keeps records issued on the first and last day, in Philippine time", async () => {
  const h = formHarness();
  h.form().setFields.setStartDate("2026-11-10");
  h.form().setFields.setEndDate("2026-11-12");
  await h.form().handleGenerate();
  assert.deepEqual(downloadedIds(h.files[0]), ['"1"', '"2"', '"3"']);
});

test("export form: only ticked columns are included, in the table's order", async () => {
  const h = formHarness();
  h.form().toggleColumn("id");
  h.form().toggleColumn("id"); // ticked again: goes back to its table position
  h.form().toggleColumn("type");
  await h.form().handleGenerate();
  assert.equal(h.files[0].text.split("\r\n")[0], '﻿"Number","Issued at"');
});

test("export form: no matching records shows a message and downloads nothing", async () => {
  const h = formHarness();
  h.form().setFields.setStartDate("2026-12-01");
  await h.form().handleGenerate();
  assert.equal(h.files.length, 0);
  assert.equal(h.exported(), 0);
  assert.deepEqual(plain(h.form().notice), {
    kind: "empty",
    message: "No records match these choices. Try a wider date range.",
  });
});

test("export form: a loading failure shows an error and downloads nothing", async () => {
  const h = formHarness({ fetchPage: async () => { throw networkError(); } });
  await h.form().handleGenerate();
  assert.equal(h.files.length, 0);
  assert.equal(h.exported(), 0);
  assert.deepEqual(plain(h.form().notice), { kind: "error", message: "Unable to generate the export. Please try again." });
  assert.equal(h.form().isPending, false);
});

test("export form: mistakes are reported on the choice they belong to", async () => {
  const h = formHarness();
  h.form().toggleType("Warning");
  h.form().toggleType("Ticket");
  await h.form().handleGenerate();
  assert.equal(h.form().fieldError.field, "types");
  h.form().toggleType("Ticket");
  for (const column of formColumns) h.form().toggleColumn(column.key);
  await h.form().handleGenerate();
  assert.equal(h.form().fieldError.field, "columns");
  h.form().toggleColumn("id");
  h.form().setFields.setStartDate("2026-11-12");
  h.form().setFields.setEndDate("2026-11-10");
  await h.form().handleGenerate();
  assert.deepEqual(plain(h.form().fieldError), { field: "dates", message: "The start date must be on or before the end date." });
  assert.equal(h.requests.length, 0);
});

test("export form on Tickets has no record type choice and still exports", async () => {
  const h = formHarness({ recordTypes: undefined });
  assert.equal(h.form().recordTypes, undefined);
  await h.form().handleGenerate();
  assert.equal(h.form().fieldError, null);
  assert.deepEqual(h.requests.at(-1), { offset: 0, type: undefined });
  assert.equal(h.files.length, 1);
});

test("ticket and inspection exports use exactly the on-screen columns, without Actions", () => {
  const reactRouter = { "react-router-dom": { useNavigate: () => () => {} } };
  const headers = (html) => [...html.matchAll(/<th(?: [^>]*)?>(.*?)<\/th>/g)].map((m) => m[1].replace(/<[^>]*>/g, ""));
  const { default: TicketList } = load("features/tickets/components/TicketList.tsx", reactRouter);
  const { TICKET_COLUMNS } = load("features/tickets/ticketColumns.ts");
  const { InspectionTable } = load("features/inspections/components/InspectionTable.tsx");
  const { INSPECTION_COLUMNS } = load("features/inspections/inspections.utils.ts");
  const row = {
    id: 1, ticketId: 1, controlNumber: "000001", enforcerFirstName: "Ramon", enforcerLastName: "Santos",
    vendorId: null, marketSectionName: "Fish Section", status: "Pending", severity: "Minor",
    penaltyType: "CashFine", type: "Ticket", paperViolatorName: "Jun Reyes", issuedAt: "2026-11-10T03:00:00Z",
  };
  const ticketHtml = renderToStaticMarkup(React.createElement(TicketList, { tickets: [row], onView() {} }));
  const inspectionHtml = renderToStaticMarkup(React.createElement(InspectionTable, {
    rows: [row], isLoading: false, isError: false, errorMessage: "", onRetry() {}, onView() {},
  }));
  assert.deepEqual(plain(TICKET_COLUMNS.map((c) => c.header)), [
    "Control number", "Enforcer", "Business name", "Registered owner", "Violator",
    "Market section", "Status", "Penalty", "Severity", "Issued at",
  ]);
  assert.deepEqual(plain(INSPECTION_COLUMNS.map((c) => c.header)), [
    "Control number", "Violator", "Enforcer", "Business name", "Registered owner",
    "Market section", "Type", "Issued at",
  ]);
  assert.deepEqual(headers(ticketHtml), [...plain(TICKET_COLUMNS.map((c) => c.header)), "Actions"]);
  assert.deepEqual(headers(inspectionHtml), [...plain(INSPECTION_COLUMNS.map((c) => c.header)), "Actions"]);
  // The screen and the file show the same text for the same record.
  assert.ok(ticketHtml.includes(TICKET_COLUMNS[1].value(row)));
  assert.ok(inspectionHtml.includes(INSPECTION_COLUMNS[1].value(row)));
});
