import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";
import test from "node:test";
import vm from "node:vm";
import React from "react";
import { renderToStaticMarkup } from "react-dom/server";
import ts from "typescript";

// Market streets slice 1: the website reads the list of market streets from the server
// instead of a fixed copy of the 8 old sections, and says "street" where it said "section".
const require = createRequire(import.meta.url);
const root = path.resolve(
  path.dirname(new URL(import.meta.url).pathname.replace(/^\/(\w:)/, "$1")),
  "..",
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
      require(id) {
        if (id in overrides) return { __esModule: true, ...overrides[id] };
        if (id.endsWith(".css"))
          return { __esModule: true, default: new Proxy({}, { get: (_, key) => key }) };
        if (!id.startsWith(".") && !id.startsWith("@/")) return require(id);
        const base = id.startsWith("@/")
          ? path.resolve(root, id.slice(2))
          : path.resolve(path.dirname(file), id);
        const resolved = [base, `${base}.ts`, `${base}.tsx`, `${base}/index.ts`, `${base}/index.tsx`]
          .find((p) => fs.existsSync(p) && fs.statSync(p).isFile());
        assert.ok(resolved, `Cannot resolve ${id}`);
        return load(path.relative(root, resolved), overrides, cache);
      },
    },
    { filename: file },
  );
  return module.exports;
}
const plain = (value) => JSON.parse(JSON.stringify(value));
const visible = (html) => html.replace(/<[^>]*>/g, " ").replace(/\s+/g, " ");

// Synthetic streets. "Test Street 13" exists only in the stand-in server, never in the website's code.
const OPEN = { id: 13, name: "Test Street 13", isActive: true, vendorCount: 0 };
const CLOSED = { id: 14, name: "Closed Street 14", isActive: false, vendorCount: 2 };

// The server and React Query's scheduling are the outer boundaries; the shared hook, the
// API adapter and the components run unchanged. Dropdown is recorded so its props can be read.
function harness(serverList = [OPEN, CLOSED]) {
  let state = { isPending: true, isError: false, data: undefined };
  const queries = [], requests = [], dropdowns = [];
  const client = { default: { async get(...args) { requests.push(args); return { data: serverList }; } } };
  const overrides = {
    "@tanstack/react-query": { useQuery(options) { queries.push(options); return state; } },
    "../client": client,
    "@/components/ui/Dropdown": { Dropdown(props) { dropdowns.push(props); return null; } },
  };
  return {
    overrides, requests, dropdowns,
    async loadFromServer() {
      state = { isPending: false, isError: false, data: await queries.at(-1).queryFn({}) };
    },
    fail() { state = { isPending: false, isError: true, data: undefined }; },
    dropdown(label) {
      const found = dropdowns.filter((props) => props.ariaLabel === label).at(-1);
      assert.ok(found, `No dropdown labelled ${label}`);
      return found;
    },
  };
}

const businessForm = (marketSectionId = 0) => ({
  form: {
    businessAccountNumber: "", businessName: "", ownerFirstName: "", ownerLastName: "",
    phoneNumber: "", email: "", houseNumber: "", street: "", barangay: "", city: "",
    businessType: "Public", marketSectionId, stallNumber: "",
  },
  errors: {}, saving: false, loading: false, loadError: null, submitError: null, createdAt: null,
  update() { }, submit: async () => { }, retry: async () => { },
});
function renderBusinessForm(h, marketSectionId) {
  const Modal = load("features/vendors/components/AdminCreateVendorModal.tsx", {
    ...h.overrides,
    "@/components/ui/Modal": { default: ({ children }) => children },
    "../hooks/useBusinessForm": { useBusinessForm: () => businessForm(marketSectionId) },
  }).default;
  return renderToStaticMarkup(React.createElement(Modal, { open: true, businessId: null, onClose() { }, onSaved: async () => { } }));
}

test("business form offers the turned-on streets the server sends, not a fixed list", async () => {
  const h = harness();
  renderBusinessForm(h);
  let field = h.dropdown("Market Street");
  assert.equal(field.disabled, true);
  assert.equal(field.triggerLabel, "Loading streets…");

  await h.loadFromServer();
  const html = renderBusinessForm(h);
  field = h.dropdown("Market Street");
  assert.equal(h.requests[0][0], "/marketsection");
  // The turned-off street is left out, so it cannot be chosen for a business.
  assert.deepEqual(plain(field.options), [{ value: "13", label: "Test Street 13" }]);
  assert.equal(field.disabled, false);
  assert.equal(field.triggerLabel, "Select market street");
  assert.match(visible(html), /Market Street \*/);
  assert.doesNotMatch(visible(html), /section/i);

  renderBusinessForm(h, 13);
  assert.equal(h.dropdown("Market Street").triggerLabel, "Test Street 13");
});

test("business form explains a failed or empty street list under the field", async () => {
  const failed = harness();
  failed.fail();
  let html = renderBusinessForm(failed);
  let field = failed.dropdown("Market Street");
  const message = (id) => html.match(new RegExp(`<small id="${id}" role="alert">([^<]*)</small>`))?.[1];
  assert.ok(field.describedBy, "the message is linked to the field");
  assert.equal(message(field.describedBy), "Unable to load market streets. Please try again.");

  const empty = harness([CLOSED]);
  renderBusinessForm(empty);
  await empty.loadFromServer();
  html = renderBusinessForm(empty);
  field = empty.dropdown("Market Street");
  assert.deepEqual(plain(field.options), []);
  assert.equal(message(field.describedBy), "No active market streets. Add one in System Configuration.");
});

const stub = () => null;
const passThrough = ({ children }) => React.createElement(React.Fragment, null, children);
const pageState = (chosen) => ({
  analytics: { stats: null, isLoading: false, refetch() { } }, analyticsError: null,
  filters: { status: "All Status", type: "All Type", search: "", marketSection: "all" },
  setFilters: { setStatus() { }, setType() { }, setSearch() { }, setMarketSection: (value) => chosen.push(value) },
  isLoading: false, isError: false, isFetching: false, total: 0, errorMessage: null,
  ticketSummary: [], inspections: [], page: 1, pageSize: 10, totalPages: 1,
  selectedTicketId: 0, isExportOpen: false, printTable: {},
});
const recordsStubs = {
  "@/components/ui/Records": { RecordsPanel: passThrough, RecordsToolbar: passThrough, RecordsFooter: stub, RecordsState: stub },
  "@/components/ui/PrintTable": { PrintTable: stub },
  "@/components/ui/TicketModal/TicketModal": { TicketModal: stub },
  "@/components/ui/PageHeader": { default: stub },
};
const filterPages = [
  ["Tickets", "features/tickets/pages/TicketsPage.tsx", "default", (chosen) => ({
    "../hooks/useTicketsPage": { useTicketsPage: () => pageState(chosen) },
    "../components/TicketList": { default: stub },
    "../components/TicketAnalyticsCard": { default: stub },
    "@/features/inspections": { PrintConfigModal: stub },
  })],
  ["Inspections", "features/inspections/pages/InspectionsPage.tsx", "InspectionsPage", (chosen) => ({
    "../hooks/useInspectionsPage": { useInspectionsPage: () => pageState(chosen) },
    "../components/InspectionTable": { InspectionTable: stub },
    "../components/PrintConfigModal": { PrintConfigModal: stub },
  })],
];
const registryProps = (chosen) => ({
  search: "", setSearch() { }, section: "all", setSection: (value) => chosen.push(value),
  complianceScore: "all", setComplianceScore() { }, page: 1, setPage() { }, vendors: [],
  total: 0, hasMore: false, isLoading: false, isFetching: false, isError: false, errorMessage: "",
  refetch() { }, exportFile() { }, print() { }, preparing: null, onViewInspections() { },
  onCreateBusiness() { }, onEditBusiness() { },
});

for (const [name, file, exportName, pageOverrides] of filterPages) {
  test(`${name} filter lists every street from the server, including turned-off ones`, async () => {
    const h = harness();
    const chosen = [];
    const render = () => renderToStaticMarkup(React.createElement(
      load(file, { ...h.overrides, ...recordsStubs, ...pageOverrides(chosen) })[exportName]));
    render();
    assert.equal(h.dropdown("Filter by market street").disabled, true);
    assert.equal(h.dropdown("Filter by market street").triggerLabel, "Loading streets…");

    await h.loadFromServer();
    render();
    const filter = h.dropdown("Filter by market street");
    assert.equal(filter.triggerLabel, "All Streets");
    assert.deepEqual(plain(filter.options), [
      { value: "all", label: "All Streets" },
      { value: "13", label: "Test Street 13" },
      { value: "14", label: "Closed Street 14" },
    ]);
    filter.onChange("14");
    assert.deepEqual(chosen, ["14"]);
  });

  test(`${name} filter keeps working with only All Streets when the list fails`, () => {
    const h = harness();
    h.fail();
    renderToStaticMarkup(React.createElement(
      load(file, { ...h.overrides, ...recordsStubs, ...pageOverrides([]) })[exportName]));
    const filter = h.dropdown("Filter by market street");
    assert.equal(filter.disabled, false);
    assert.equal(filter.triggerLabel, "All Streets");
    assert.deepEqual(plain(filter.options), [{ value: "all", label: "All Streets" }]);
  });
}

test("Businesses filter lists every street from the server and shows the chosen one", async () => {
  const h = harness();
  const chosen = [];
  const Registry = () => load("features/vendors/components/AdminVendorRegistry.tsx", h.overrides).default;
  renderToStaticMarkup(React.createElement(Registry(), registryProps(chosen)));
  assert.equal(h.dropdown("Filter by market street").triggerLabel, "Loading streets…");
  await h.loadFromServer();
  renderToStaticMarkup(React.createElement(Registry(), registryProps(chosen)));
  const filter = h.dropdown("Filter by market street");
  assert.equal(filter.triggerLabel, "Street: All");
  assert.deepEqual(plain(filter.options), [
    { value: "all", label: "All Streets" },
    { value: "13", label: "Test Street 13" },
    { value: "14", label: "Closed Street 14" },
  ]);
  filter.onChange("14");
  assert.deepEqual(chosen, ["14"]);
  renderToStaticMarkup(React.createElement(Registry(), { ...registryProps(chosen), section: "14" }));
  assert.equal(h.dropdown("Filter by market street").triggerLabel, "Street: Closed Street 14");
});

// React state is the outer boundary here; the filter hooks run unchanged.
function filterHook(file, name) {
  const states = [];
  let cursor = 0;
  const hooks = load(file, {
    react: {
      useState(initial) {
        const i = cursor++;
        if (!(i in states)) states[i] = initial;
        return [states[i], (value) => { states[i] = value; }];
      },
    },
    "@/hooks/useDebounce": { default: (value) => value },
  });
  return () => { cursor = 0; return hooks[name](); };
}

test("choosing a street in the Tickets and Inspections filters sends that street's number", () => {
  for (const render of [
    filterHook("features/tickets/hooks/useTicketFilters.ts", "useTicketFilters"),
    filterHook("features/inspections/hooks/useInspectionFilters.ts", "useInspectionFilters"),
  ]) {
    assert.equal(render().queryParams.marketSectionId, undefined);
    render().setFilters.setMarketSection("14");
    assert.equal(render().queryParams.marketSectionId, 14);
    render().setFilters.setMarketSection("all");
    assert.equal(render().queryParams.marketSectionId, undefined);
  }
});

test("table columns, analytics titles and the Recommended Actions heading say street", () => {
  const header = (columns) => columns.find((column) => column.key === "section").header;
  assert.equal(header(load("features/tickets/ticketColumns.ts").TICKET_COLUMNS), "Market street");
  assert.equal(header(load("features/inspections/inspections.utils.ts").INSPECTION_COLUMNS), "Market street");
  assert.equal(header(load("features/vendors/businessTableColumns.ts").BUSINESS_COLUMNS), "Market street");

  const panel = { data: [], isLoading: false, isError: false, errorMessage: "", onRetry() { } };
  const chart = visible(renderToStaticMarkup(React.createElement(
    load("features/analytics/components/MarketSectionAggregationChart.tsx").default, panel)));
  assert.match(chart, /Market Street Aggregation/);
  assert.match(chart, /Warnings and tickets in each market street\./);
  assert.match(chart, /No market street data available\./);
  const hotspots = visible(renderToStaticMarkup(React.createElement(
    load("features/analytics/components/HotspotRankingTable.tsx").default, panel)));
  assert.match(hotspots, /Market streets with the most warnings and tickets\./);
  assert.match(hotspots, / Market Street /);
  for (const text of [chart, hotspots]) assert.doesNotMatch(text, /section/i);

  const list = visible(renderToStaticMarkup(React.createElement(
    load("features/recommendations/components/SectionList.tsx").default,
    { sections: [], selectedId: null, onSelect() { } })));
  assert.match(list, / Streets /);
  assert.doesNotMatch(list, /section/i);
});

test("the ticket pop-up says market street but an ordinance still says Section 69", () => {
  const Details = load("components/ui/TicketModal/modal/TicketViolationDetailsSection.tsx").default;
  const warning = {
    type: "Warning", vendorId: null, marketSectionName: "Test Street 13", issuePlace: "Near stall 13",
    issuedAt: "2026-11-16T02:00:00Z", categories: [], description: "Synthetic",
    violations: [{ ordinanceNo: "2019-12", series: "2019", section: "69", specificCategory: null }],
  };
  const details = visible(renderToStaticMarkup(React.createElement(Details, { detail: warning })));
  assert.match(details, /MARKET STREET Test Street 13/);
  assert.match(details, /Section 69/);
  assert.doesNotMatch(details, /MARKET SECTION/);

  const Violator = load("components/ui/TicketModal/modal/TicketViolatorInfoSection.tsx").default;
  const ticket = {
    type: "Ticket", vendorId: 4, personId: null, paperViolatorName: "Jun Reyes",
    businessSnapshot: { businessAccountNumber: "0012", businessType: "Public", businessName: "Reyes Fish",
      stallNumber: "F-12", registeredOwnerName: "Juan Reyes", marketSectionName: "Test Street 13", businessAddress: "Marikina" },
  };
  const violator = visible(renderToStaticMarkup(React.createElement(Violator, { detail: ticket })));
  assert.match(violator, /MARKET STREET: Test Street 13/);
  assert.doesNotMatch(violator, /MARKET SECTION/);
});
