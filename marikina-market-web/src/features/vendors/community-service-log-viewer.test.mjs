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
  "../..",
);

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
      Error,
      Date,
      URL,
      Intl,
      Number,
      Math,
      Array,
      Object,
      String,
      // The window portals into the page body; the portal itself is replaced below.
      document: { body: null },
      require(id) {
        if (id in overrides) return { __esModule: true, ...overrides[id] };
        if (id === "@/config/env")
          return { __esModule: true, default: { apiBaseUrl: "/api" } };
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
        return load(path.relative(root, resolved), overrides, cache);
      },
    },
    { filename: file },
  );
  return module.exports;
}

function findElement(node, predicate) {
  if (!node || typeof node !== "object") return null;
  if (Array.isArray(node)) {
    for (const child of node) {
      const found = findElement(child, predicate);
      if (found) return found;
    }
    return null;
  }
  if (node.props && predicate(node)) return node;
  return findElement(node.props?.children, predicate);
}

const ramon = {
  ticketId: 418,
  controlNumber: "2026-000418",
  businessAccountNumber: "06-2025-01177",
  vendorName: "Ramon Dela Cruz",
  completedHours: 6.5,
  totalHours: 8,
  lastUpdated: "2026-11-12T03:00:00Z",
  proofDocumentCount: 3,
  status: "Pending",
};
const liza = {
  ...ramon,
  ticketId: 431,
  controlNumber: "2026-000431",
  vendorName: "Liza Manalo",
  completedHours: 0,
  totalHours: 4,
  proofDocumentCount: 0,
};

// Only React's state hook is replaced, so the row can be "clicked" and the
// table rendered again without a browser.
function rowHarness() {
  const states = [];
  let cursor = 0;
  const { default: AdminCommunityServiceLogs } = load(
    "features/vendors/components/AdminCommunityServiceLogs.tsx",
    {
      react: {
        ...React,
        useState(initial) {
          const i = cursor++;
          if (!(i in states)) states[i] = initial;
          return [states[i], (value) => (states[i] = value)];
        },
      },
    },
  );
  const props = {
    logs: [ramon, liza],
    page: 1,
    setPage() {},
    status: "all",
    setStatus() {},
    totalLabel: 2,
    offset: 0,
    totalPages: 1,
    hasMore: false,
    isLoading: false,
    isError: false,
    errorMessage: "",
    refetch() {},
    getProgressStatus: () => "inProgress",
  };
  return {
    render() {
      cursor = 0;
      return AdminCommunityServiceLogs(props);
    },
  };
}

function documentCell(tree, log) {
  const table = findElement(tree, (node) => Array.isArray(node.props.columns));
  const column = table.props.columns.find(
    (item) => item.key === "proofDocumentCount",
  );
  return column.render(log);
}

const logWindow = (node) => "log" in node.props && "onClose" in node.props;

test("the docs chip opens the log window for its own row, and the Upload button is gone", () => {
  const harness = rowHarness();
  let tree = harness.render();
  assert.equal(findElement(tree, logWindow).props.log, null);

  const ramonCell = documentCell(tree, ramon);
  const ramonMarkup = renderToStaticMarkup(ramonCell);
  assert.doesNotMatch(ramonMarkup, /Upload/);
  assert.match(ramonMarkup, /^<button[^>]*type="button"/);
  assert.doesNotMatch(ramonMarkup, /disabled/);
  assert.match(ramonMarkup, />3 docs</);
  assert.match(
    ramonMarkup,
    /aria-label="3 docs, view community service logs for Ramon Dela Cruz"/,
  );

  findElement(ramonCell, (node) => node.type === "button").props.onClick();
  tree = harness.render();
  assert.equal(findElement(tree, logWindow).props.log.ticketId, 418);

  findElement(tree, logWindow).props.onClose();
  tree = harness.render();
  assert.equal(findElement(tree, logWindow).props.log, null);
});

test("a row with no proof documents shows a chip that cannot be opened", () => {
  const harness = rowHarness();
  const markup = renderToStaticMarkup(documentCell(harness.render(), liza));
  assert.match(markup, /^<button[^>]*disabled=""/);
  assert.match(markup, />0 docs</);
  assert.doesNotMatch(markup, /Upload/);
});

// The server (HTTP) and the browser-only pieces (portal into the page,
// full-size photo viewer library) are the outer boundaries.
function windowHarness(queryState) {
  const queries = [];
  const requests = [];
  const server = {
    default: {
      async get(...args) {
        requests.push(args);
        return { data: ramonTicket };
      },
    },
  };
  const { default: CommunityServiceLogModal } = load(
    "features/vendors/components/CommunityServiceLogModal.tsx",
    {
      "@tanstack/react-query": {
        useQuery(options) {
          queries.push(options);
          return { refetch() {}, ...queryState };
        },
      },
      "@/api/client": server,
      "../client": server,
      "react-dom": { createPortal: (node) => node },
      "yet-another-react-lightbox": { default: () => null },
      "yet-another-react-lightbox/plugins": { Thumbnails: {}, Zoom: {} },
    },
  );
  return {
    queries,
    requests,
    markup: (log) =>
      renderToStaticMarkup(
        React.createElement(CommunityServiceLogModal, { log, onClose() {} }),
      ),
  };
}

const ramonTicket = {
  ticketId: 418,
  type: "Ticket",
  penaltyType: "CommunityService",
  communityServiceHours: 8,
  hoursCompleted: 6.5,
  proofUrls: [],
  communityServiceLogs: [
    { serviceDate: "2026-11-03T01:00:00Z", hoursWorked: 2, proofUrl: "https://storage.example.com/cs-1.jpg?sig=a" },
    { serviceDate: "2026-11-07T01:00:00Z", hoursWorked: 3, proofUrl: "https://storage.example.com/cs-2.jpg?sig=b" },
    { serviceDate: "2026-11-12T01:00:00Z", hoursWorked: 1.5, proofUrl: "https://storage.example.com/cs-3.jpg?sig=c" },
  ],
};

test("the log window loads that ticket and shows whose log it is, the progress and every entry", async () => {
  const harness = windowHarness({
    data: ramonTicket,
    isLoading: false,
    isError: false,
  });
  const markup = harness.markup(ramon);

  assert.equal(harness.queries.length, 1);
  assert.equal(harness.queries[0].enabled, true);
  await harness.queries[0].queryFn();
  assert.equal(harness.requests[0][0], "/admin/tickets/418");

  assert.match(markup, /role="dialog"/);
  assert.match(markup, />Ramon Dela Cruz</);
  assert.match(
    markup,
    /Control number 2026-000418 · Business Account Number 06-2025-01177/,
  );
  assert.match(markup, /6\.5 of 8 hrs completed/);
  assert.match(markup, /3 photos/);
  const entries = [...markup.matchAll(/<span>(\d\d\/\d\d\/\d{4})<\/span><span[^>]*>([\d.]+ hrs?)<\/span>/g)]
    .map((match) => `${match[1]} ${match[2]}`);
  assert.deepEqual(entries, [
    "11/03/2026 2 hrs",
    "11/07/2026 3 hrs",
    "11/12/2026 1.5 hrs",
  ]);
});

test("an unregistered vendor's log window names them and skips the missing account number", () => {
  const harness = windowHarness({ data: ramonTicket, isLoading: false, isError: false });
  const markup = harness.markup({ ...ramon, vendorName: null, businessAccountNumber: null });
  assert.match(markup, />Unregistered vendor</);
  assert.match(markup, /Control number 2026-000418</);
  assert.doesNotMatch(markup, /Business Account Number/);
});

test("the log window shows loading and error states instead of the log", () => {
  const loading = windowHarness({ data: undefined, isLoading: true, isError: false }).markup(ramon);
  assert.match(loading, /role="status"[^>]*>Loading community service logs\.\.\.</);
  assert.doesNotMatch(loading, /Completion Progress/);

  const failed = windowHarness({
    data: undefined,
    isLoading: false,
    isError: true,
    // What the HTTP library reports when the server cannot be reached.
    error: Object.assign(new Error("Network Error"), { isAxiosError: true }),
  }).markup(ramon);
  assert.match(failed, /role="alert"/);
  assert.match(failed, /Unable to load community service logs\./);
  assert.match(failed, />Try again</);
  assert.doesNotMatch(failed, /Completion Progress/);
});

test("the log window is not drawn and loads nothing while no row is chosen", () => {
  const harness = windowHarness({ data: undefined, isLoading: false, isError: false });
  assert.equal(harness.markup(null), "");
  assert.equal(harness.queries[0].enabled, false);
});
