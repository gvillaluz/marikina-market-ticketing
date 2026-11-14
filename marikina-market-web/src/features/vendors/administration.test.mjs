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

// React/query scheduling and HTTP are outer boundaries. Real feature hooks,
// debounce, adapters, components and Pagination run unchanged.
function harness(file, hookName, extraGlobals = {}) {
  const states = [],
    effects = [],
    timers = new Map(),
    queries = [],
    navigation = [],
    requests = [],
    tableExports = [];
  let stateCursor = 0,
    effectCursor = 0,
    refCursor = 0,
    timerId = 0;
  const refs = [], writes = [];
  let writeHandler = async () => ({ data: queryState.data });
  let queryState = {
    data: { items: [], total: 30, hasMore: true },
    isLoading: false,
    isFetching: false,
    isError: false,
  };
  const pendingEffects = [];
  const modules = load(
    file,
    {
      react: {
        useRef(initial) {
          const i = refCursor++;
          return refs[i] ??= { current: initial };
        },
        useState(initial) {
          const i = stateCursor++;
          if (!(i in states))
            states[i] = typeof initial === "function" ? initial() : initial;
          return [
            states[i],
            (value) => {
              states[i] =
                typeof value === "function" ? value(states[i]) : value;
            },
          ];
        },
        useMemo: (create) => create(),
        useEffect(callback, deps) {
          const i = effectCursor++;
          if (
            !effects[i] ||
            deps.some(
              (value, index) => !Object.is(value, effects[i].deps[index]),
            )
          ) {
            effects[i]?.cleanup?.();
            effects[i] = { deps };
            pendingEffects.push(() => {
              effects[i].cleanup = callback();
            });
          }
        },
      },
      "react-router-dom": {
        useNavigate:
          () =>
            (...args) =>
              navigation.push(args),
      },
      "@tanstack/react-query": {
        useQuery(options) {
          queries.push(options);
          return {
            ...queryState,
            refetch() {
              return options.queryFn();
            },
          };
        },
      },
      // Export/Print are covered by table-export.test.mjs; here we only
      // check what each page hands to them.
      "@/hooks/useTableExport": {
        useTableExport(options) {
          tableExports.push(options);
          return {
            preparing: null,
            exportFile: options.fetchPage,
            print: options.fetchPage,
            printTable: { title: options.title, rows: null },
          };
        },
      },
      "@/api/client": {
        default: {
          async get(...args) {
            requests.push(args);
            return { data: queryState.data };
          },
          async post(...args) { writes.push(["post", ...args]); return writeHandler(...args); },
          async put(...args) { writes.push(["put", ...args]); return writeHandler(...args); },
        },
      },
    },
    {
      setTimeout(callback) {
        timers.set(++timerId, callback);
        return timerId;
      },
      clearTimeout(id) {
        timers.delete(id);
      },
      ...extraGlobals,
    },
  );
  return {
    queries,
    navigation,
    requests,
    tableExports,
    writes,
    setWriteHandler(handler) { writeHandler = handler; },
    setQuery(value) {
      queryState = { ...queryState, ...value };
    },
    render(...args) {
      stateCursor = effectCursor = refCursor = 0;
      queries.length = 0;
      return modules[hookName](...args);
    },
    flushEffects() {
      while (pendingEffects.length) pendingEffects.shift()();
    },
    flushTimers() {
      const callbacks = [...timers.values()];
      timers.clear();
      callbacks.forEach((callback) => callback());
    },
  };
}

test("registry filter/search changes start at page one and debounce blocks paging", async () => {
  const h = harness(
    "features/vendors/hooks/useAdminVendorsPage.ts",
    "useAdminVendorsPage",
  );
  h.render();
  h.flushEffects();
  h.flushTimers();
  h.render().registry.setPage(3);
  assert.equal(h.render().registry.page, 3);
  h.render().registry.setSection("2");
  assert.equal(h.render().registry.page, 1);
  let query = h.queries.find((q) => q.queryKey[0] === "admin-vendors");
  await query.queryFn();
  assert.equal(h.requests.at(-1)[1].params.offset, 0);
  assert.equal(h.requests.at(-1)[1].params.marketSectionId, 2);
  h.render().registry.setPage(2);
  h.render().registry.setComplianceScore("70-84");
  assert.equal(h.render().registry.page, 1);
  h.render().registry.setPage(2);
  h.render().registry.setSearch("Reyes");
  assert.equal(h.render().registry.page, 1);
  assert.equal(h.render().registry.isLoading, true);
  h.render().registry.setPage(2);
  assert.equal(h.render().registry.page, 1);
  h.flushEffects();
  h.flushTimers();
  const registry = h.render().registry;
  assert.equal(registry.isLoading, false);
  query = h.queries.find((q) => q.queryKey[0] === "admin-vendors");
  await query.queryFn();
  assert.equal(h.requests.at(-1)[1].params.search, "Reyes");
  assert.equal(h.requests.at(-1)[1].params.offset, 0);
  registry.onViewInspections({
    vendorId: 70,
    vendorName: "Juan Reyes",
    businessAccountNumber: "MM-70",
  });
  assert.equal(h.navigation[0][0], "/admin/vendors/70/inspections");
  registry.setPage(3);
  h.setQuery({ data: { items: [], total: 0, hasMore: false } });
  h.render().registry.setPage(2);
  assert.equal(h.render().registry.page, 1);
});

test("business list Export and Print collect every matching business with the table's columns", async () => {
  const { toCsv } = load("utils/tableExport.ts");
  const h = harness("features/vendors/hooks/useAdminVendorsPage.ts", "useAdminVendorsPage");
  h.render().registry.setSection("2");
  h.render();
  const latest = h.tableExports.at(-1);
  assert.equal(latest.fileName, "business-registry.csv");
  assert.equal(latest.title, "Business registry");
  await latest.fetchPage(20);
  assert.equal(h.requests.at(-1)[0], "/admin/vendors");
  assert.equal(h.requests.at(-1)[1].params.offset, 20);
  assert.equal(h.requests.at(-1)[1].params.marketSectionId, 2);
  const [header, row] = toCsv(latest.columns, [{
    vendorId: 4, businessName: "Reyes Fresh Meats", businessAccountNumber: "0012345",
    vendorName: "Juan Reyes", marketSectionName: "Meat", type: "Public",
    complianceScore: 90, warningCount: 0, ticketCount: 2,
  }]).split("\r\n");
  assert.equal(header, '"Business name","Business account number","Registered owner","Market section","Type","Compliance score","Warnings","Tickets"');
  assert.equal(row, '"Reyes Fresh Meats","0012345","Juan Reyes","Meat","Public","90%","0","2"');
  const page = h.render();
  assert.equal(page.registry.exportFile, h.tableExports.at(-1).fetchPage);
  assert.equal(page.registry.print, h.tableExports.at(-1).fetchPage);
  assert.equal(page.registryPrint.title, "Business registry");
});

test("business record page and its history never call the business a vendor", () => {
  const visibleText = (html) => html.replace(/<[^>]*>/g, " ");
  const stub = () => null;
  const page = (vendorId) => renderToStaticMarkup(React.createElement(load(
    "features/vendors/pages/AdminVendorInspectionPage.tsx",
    {
      "react-router-dom": {
        useParams: () => ({ vendorId }), useNavigate: () => noop,
        useLocation: () => ({ state: null }),
        Link: ({ children }) => React.createElement("a", null, children),
      },
      "../hooks/useAdminVendorProfile": {
        useAdminVendorProfile: () => ({ isProfileLoading: true, isScoreLoading: true }),
      },
      "../hooks/useAdminVendorInspectionPage": {
        useAdminVendorInspectionPage: () => ({ selectedTicketId: 0 }),
      },
      "../components/AdminVendorInspectionHistory": { default: stub },
      "@/components/ui/TicketModal/TicketModal": { TicketModal: stub },
    },
  ).default));
  const missing = visibleText(page("abc"));
  assert.match(missing, /Business record unavailable/);
  assert.match(missing, /This business record could not be found\./);
  assert.match(missing, /Back to Businesses/);
  assert.doesNotMatch(missing, /vendor/i);
  const foundHtml = page("7");
  const found = visibleText(foundHtml);
  assert.match(found, /Business Record/);
  assert.match(found, /Business Inspection History/);
  assert.doesNotMatch(found, /vendor/i);
  assert.match(foundHtml, /aria-label="Business performance summary"/);
  const historyHtml = renderComponent("AdminVendorInspectionHistory", historyProps);
  assert.match(visibleText(historyHtml), /Complete activity log for this business\./);
  assert.match(historyHtml, /placeholder="Search by control number or ordinance\.\.\."/);
  assert.doesNotMatch(visibleText(historyHtml), /vendor/i);
  assert.doesNotMatch(historyHtml, /(placeholder|aria-label)="[^"]*vendor/i);
});

test("inspection filters reset immediately; changing vendor drops old page and ticket selection", () => {
  const h = harness(
    "features/vendors/hooks/useAdminVendorInspectionPage.ts",
    "useAdminVendorInspectionPage",
  );
  h.render(70);
  h.flushEffects();
  h.flushTimers();
  h.render(70).setPage(3);
  h.render(70).setType("Ticket");
  assert.equal(h.render(70).page, 1);
  h.render(70).setPage(2);
  h.render(70).setSortDirection("asc");
  assert.equal(h.render(70).page, 1);
  h.render(70).setPage(2);
  h.render(70).setSelectedTicketId(123);
  const next = h.render(71);
  assert.equal(next.page, 1);
  assert.equal(next.selectedTicketId, 0);
  assert.equal(h.queries[0].queryKey[2].offset, 0);
  h.flushEffects();
  assert.equal(h.render(70).selectedTicketId, 0);
});

const noop = () => { };
const registryProps = {
  search: "",
  setSearch: noop,
  section: "all",
  setSection: noop,
  complianceScore: "all",
  setComplianceScore: noop,
  page: 1,
  setPage: noop,
  vendors: [],
  total: 20,
  hasMore: true,
  isLoading: false,
  isFetching: false,
  isError: false,
  errorMessage: "Connection unavailable",
  refetch: noop,
  exportFile: noop,
  print: noop,
  preparing: null,
  onViewInspections: noop,
};
const historyProps = {
  search: "",
  onSearchChange: noop,
  type: "all",
  onTypeChange: noop,
  sortDirection: "desc",
  onSortDirectionChange: noop,
  page: 1,
  totalPages: 2,
  onPageChange: noop,
  inspections: [],
  total: 20,
  hasMore: true,
  isLoading: false,
  isFetching: false,
  isError: false,
  errorMessage: "Connection unavailable",
  onRetry: noop,
  onExport: noop,
  onPrint: noop,
  preparing: null,
  onView: noop,
};
function renderComponent(file, props) {
  return renderToStaticMarkup(
    React.createElement(
      load(`features/vendors/components/${file}.tsx`).default,
      props,
    ),
  );
}

test("registry and history enable Next only when more rows exist and block controls during retry", () => {
  for (const [file, props] of [
    ["AdminVendorRegistry", registryProps],
    ["AdminVendorInspectionHistory", historyProps],
  ]) {
    let html = renderComponent(file, props);
    assert.doesNotMatch(
      html,
      /<button[^>]*disabled=""[^>]*aria-label="Next page"/,
    );
    html = renderComponent(file, { ...props, hasMore: false });
    assert.match(html, /<button[^>]*disabled=""[^>]*aria-label="Next page"/);
    html = renderComponent(file, { ...props, isFetching: true });
    assert.match(html, /<button[^>]*disabled=""[^>]*aria-label="Next page"/);
    html = renderComponent(file, { ...props, isError: true, isFetching: true });
    assert.match(html, /role="alert"/);
    assert.match(html, /Connection unavailable/);
    assert.match(html, /<button[^>]*disabled=""[^>]*>[^<]*Retrying/);
  }
});

test("empty last pages show a zero range rather than an impossible end row", () => {
  assert.match(
    renderComponent("AdminVendorRegistry", {
      ...registryProps,
      page: 3,
      total: 0,
      hasMore: false,
    }),
    /Showing 0 to 0 of 0 entries/,
  );
  assert.match(
    renderComponent("AdminVendorInspectionHistory", {
      ...historyProps,
      page: 3,
      total: 0,
      hasMore: false,
    }),
    /Showing 0 to 0 of 0 entries/,
  );
});

test("unsafe vendor IDs disable profile, score and history queries", () => {
  const profile = harness(
    "features/vendors/hooks/useAdminVendorProfile.ts",
    "useAdminVendorProfile",
  );
  const history = harness(
    "features/vendors/hooks/useAdminVendorInspectionHistory.ts",
    "useAdminVendorInspectionHistory",
  );
  for (const id of [0, -1, NaN, 1.5, Number.MAX_SAFE_INTEGER + 1]) {
    profile.render(id);
    assert.ok(profile.queries.every((q) => q.enabled === false));
    history.render(id, { offset: 0, sortDirection: "desc" });
    assert.equal(history.queries[0].enabled, false);
  }
});

test("business form requires a stall only for Public businesses and accepts optional contacts", () => {
  const { validateBusiness } = load("features/vendors/business.validation.ts");
  const record = {
    businessAccountNumber: "0001842", businessName: "Reyes Fish Store", ownerFirstName: "Juan",
    ownerLastName: "Reyes", houseNumber: "12", street: "J. P. Rizal", barangay: "Sta. Elena",
    city: "Marikina City", marketSectionId: 1, businessType: "Private", stallNumber: "",
    phoneNumber: "", email: "",
  };
  assert.equal(Object.keys(validateBusiness(record)).length, 0);
  assert.match(validateBusiness({ ...record, businessType: "Public" }).stallNumber, /required/);
  assert.equal(Object.keys(validateBusiness({ ...record, businessType: "Public", stallNumber: "F-12" })).length, 0);
  assert.ok(validateBusiness({ ...record, email: "not-an-email" }).email);
  assert.ok(validateBusiness({ ...record, phoneNumber: "invalid" }).phoneNumber);
  assert.ok(validateBusiness({ ...record, businessAccountNumber: " " }).businessAccountNumber);
  assert.ok(validateBusiness({ ...record, businessType: "Other" }).businessType);
});

test("business creation submits once, has no credentials and retains a failed draft", async () => {
  const h = harness("features/vendors/hooks/useBusinessForm.ts", "useBusinessForm");
  let closed = 0, refreshed = 0;
  const args = [true, null, async () => { refreshed++; }, () => { closed++; }];
  h.render(...args); h.flushEffects();
  let state = h.render(...args);
  for (const [key, value] of Object.entries({
    businessAccountNumber: "0001842", businessName: "Reyes Fish Store",
    ownerFirstName: "Juan", ownerLastName: "Reyes", houseNumber: "12", street: "J. P. Rizal",
    barangay: "Sta. Elena", city: "Marikina City", marketSectionId: 1, businessType: "Private"
  })) state.update(key, value);
  let fail;
  h.setWriteHandler(() => new Promise((_, reject) => { fail = reject; }));
  state = h.render(...args);
  const first = state.submit();
  await state.submit();
  assert.equal(h.writes.length, 1);
  assert.equal(h.writes[0][1], "/admin/businesses");
  assert.equal(h.writes[0][2].businessAccountNumber, "0001842");
  assert.equal("password" in h.writes[0][2], false);
  assert.equal("username" in h.writes[0][2], false);
  fail(new Error("Save unavailable")); await first;
  state = h.render(...args);
  assert.equal(state.form.businessName, "Reyes Fish Store");
  assert.ok(state.submitError); assert.equal(closed, 0); assert.equal(refreshed, 0);
  h.setWriteHandler(async () => ({ data: { id: 70 } }));
  await state.submit();
  assert.equal(closed, 1); assert.equal(refreshed, 1);
});

test("business editing loads saved fields and sends only editable fields", async () => {
  const h = harness("features/vendors/hooks/useBusinessForm.ts", "useBusinessForm");
  const record = {
    id: 70, businessAccountNumber: "0001842", businessName: "Reyes Fish Store",
    ownerFirstName: "Juan", ownerLastName: "Reyes", houseNumber: "12", street: "J. P. Rizal",
    barangay: "Sta. Elena", city: "Marikina City", marketSectionId: 1, businessType: "Public", stallNumber: "F-12",
    phoneNumber: null, email: null, createdAt: "2026-01-01T00:00:00Z", status: "Active"
  };
  h.setQuery({ data: record });
  const args = [true, 70, async () => { }, () => { }];
  h.render(...args); h.flushEffects();
  let state = h.render(...args);
  assert.equal(state.form.ownerLastName, "Reyes");
  state.update("businessName", "Reyes Fresh Fish");
  state = h.render(...args); await state.submit();
  assert.equal(h.writes[0][0], "put"); assert.equal(h.writes[0][1], "/admin/businesses/70");
  assert.equal(h.writes[0][2].businessName, "Reyes Fresh Fish");
  for (const field of ["id", "createdAt", "status", "userId"]) assert.equal(field in h.writes[0][2], false);
});

// Synthetic records. Expected text worked out by hand: a ticket shows the name written on paper,
// a warning shows the confirmed person, and an old ticket without a written name says so.
const violatorRows = [
  {
    ticketId: 1, type: "Ticket", controlNumber: "000456", issuedAt: "2026-11-10T01:00:00Z",
    ordinanceNumbers: ["2019-12"], enforcerName: "Test Officer", paperViolatorName: "Jose Ramos",
    personFullName: "Jose P. Ramos", businessSnapshot: { businessName: "Aling Nena's Store" },
  },
  {
    ticketId: 2, type: "Warning", controlNumber: "WRN-0011", issuedAt: "2026-11-09T01:00:00Z",
    ordinanceNumbers: ["2019-12"], enforcerName: "Test Officer", paperViolatorName: null,
    personFullName: "Maria Santos", businessSnapshot: null,
  },
  {
    ticketId: 3, type: "Ticket", controlNumber: null, issuedAt: "2026-11-08T01:00:00Z",
    ordinanceNumbers: [], enforcerName: "Test Officer", paperViolatorName: null,
    personFullName: null, businessSnapshot: null,
  },
];

test("business history shows a Violator column after Type with the recorded violator", () => {
  const html = renderComponent("AdminVendorInspectionHistory", { ...historyProps, inspections: violatorRows });
  const headers = [...html.matchAll(/<th[^>]*>(.*?)<\/th>/g)].map((match) => match[1].replace(/<[^>]*>/g, ""));
  assert.deepEqual(headers, ["CONTROL NUMBER", "TYPE", "VIOLATOR", "DATE &amp; TIME", "ORDINANCE(S)", "ENFORCER", "ACTION"]);
  const violatorCells = [...html.matchAll(/<tr[^>]*>(.*?)<\/tr>/g)].slice(1)
    .map((row) => [...row[1].matchAll(/<td[^>]*>(.*?)<\/td>/g)][2][1].replace(/<[^>]*>/g, ""));
  assert.deepEqual(violatorCells, ["Jose Ramos", "Maria Santos", "Unconfirmed (legacy record)"]);
});

test("business history Export and Print collect every matching record with Business name and Violator columns", async () => {
  const { toCsv } = load("utils/tableExport.ts");
  const h = harness("features/vendors/hooks/useAdminVendorInspectionPage.ts", "useAdminVendorInspectionPage");
  h.render(70).setType("Ticket");
  h.render(70);
  const options = h.tableExports.at(-1);
  assert.equal(options.fileName, "vendor-inspection-history.csv");
  await options.fetchPage(10);
  assert.equal(h.requests.at(-1)[0], "/admin/vendors/70/inspections");
  assert.equal(h.requests.at(-1)[1].params.offset, 10);
  assert.equal(h.requests.at(-1)[1].params.ticketType, "Ticket");
  const lines = toCsv(options.columns, violatorRows).split("\r\n");
  assert.equal(lines[0], '"Control number","Business name","Type","Violator","Date & time","Ordinance(s)","Enforcer"');
  assert.deepEqual(lines.slice(1).map((line) => line.split('","')[3]), ["Jose Ramos", "Maria Santos", "Unconfirmed (legacy record)"]);
  assert.equal(h.render(70).exportFile, h.tableExports.at(-1).fetchPage);
});
