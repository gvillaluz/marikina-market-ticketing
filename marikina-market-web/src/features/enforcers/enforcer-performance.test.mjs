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

// The enforcer performance page. The three data hooks are replaced with fixed answers so each
// case (loaded, failed, empty, bad link) can be drawn; everything the page draws is the real code.

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

const idle = { isLoading: false, isFetching: false, isError: false, errorMessage: "", onRetry() {} };
const failed = (errorMessage) => ({ ...idle, isError: true, errorMessage });

const profile = {
  userId: 8, username: "enforcer.cruz", firstName: "Maria", lastName: "Cruz", phoneNumber: "09170000000",
  email: "enforcer.cruz@example.invalid", status: "Active", role: "MarketEnforcer",
  hiredAt: "2026-01-05T00:00:00Z", profileUrl: "", lastInspectionDate: "2026-11-10T02:00:00Z",
};
const performance = {
  enforcerId: 8, totalInspections: 6, resolutionRate: 75, warningRatio: 33.3, ticketRatio: 66.7,
  monthlyInspections: Array.from({ length: 12 }, (_, i) => ({ month: i + 1, totalIssuedTickets: i === 10 ? 6 : 0 })),
};
const row = (ticketId, type, status, names = {}) => ({
  ticketId, type, status, controlNumber: type === "Warning" ? `WRN-000${ticketId}` : `00045${ticketId}`,
  issuedAt: "2026-11-10T02:00:00Z", vendorId: null, paperViolatorName: null, personFullName: null,
  businessName: null, registeredOwnerName: null, marketSectionId: 1, marketSectionName: "Dry Goods",
  businessSnapshot: null, ...names,
});
const tenRows = Array.from({ length: 10 }, (_, i) => row(i + 1, "Ticket", "Pending"));

function renderPage({
  id = "8",
  profileHook = { profile, profileProcess: idle },
  performanceHook = { performance, performanceProcess: idle },
  historyHook = {},
  isAdmin = true,
} = {}) {
  const history = {
    inspections: tenRows, page: 1, setPage() {}, total: 25, totalPages: 3, pageSize: 10, historyProcess: idle,
    ...historyHook,
  };
  const { default: Page } = load("features/enforcers/pages/EnforcerPerformancePage.tsx", {
    "react-router-dom": { ...realRouter, useParams: () => ({ id }), useNavigate: () => () => {} },
    "@/context/AuthContext": { useAuth: () => ({ isAdmin }) },
    "@/features/enforcers/hooks/useFetchProfile": { useFetchProfile: () => profileHook },
    "@/features/enforcers/hooks/useFetchPerformance": { useFetchPerformance: () => performanceHook },
    "@/features/enforcers/hooks/useFetchHistory": { useFetchHistory: () => history },
    "@/components/ui/TicketModal/TicketModal": { TicketModal: () => null },
  });
  // The breadcrumb's link needs a router around the page.
  return renderToStaticMarkup(
    React.createElement(realRouter.MemoryRouter, null, React.createElement(Page)),
  );
}

// The history table's rows, as the text of each cell.
const tableRows = (html) =>
  [...html.matchAll(/<tr[^>]*>([^]*?)<\/tr>/g)]
    .map(([, cells]) =>
      [...cells.matchAll(/<td[^>]*>([^]*?)<\/td>/g)].map(([, cell]) =>
        cell.replace(/<[^>]+>/g, " ").replace(/&#x27;/g, "'").replace(/\s+/g, " ").trim(),
      ),
    )
    .filter((cells) => cells.length > 0);

test("a breadcrumb leads back to the Enforcers page", () => {
  const html = renderPage();
  assert.match(html, /<nav[^>]*aria-label="Breadcrumb"/);
  assert.match(html, /<a [^>]*href="\/enforcers"[^>]*>Enforcers<\/a>/);
  assert.match(html, /aria-current="page"[^>]*>Cruz, Maria</);
  // While the profile loads, the trail still leads back.
  const loading = renderPage({ profileHook: { profile: undefined, profileProcess: { ...idle, isLoading: true } } });
  assert.match(loading, /href="\/enforcers"/);
  assert.match(loading, /aria-current="page"[^>]*>Enforcer</);
});

test("history rows show the violator, business, owner and street for each kind of record", () => {
  const store = { vendorId: 17, businessName: "Aling Nena's Store", registeredOwnerName: "Nena Reyes" };
  const rows = [
    // Registered ticket: business and owner as they were when issued; the violator written on the ticket.
    row(1, "Ticket", "Overdue", {
      ...store, paperViolatorName: "JUAN D. CRUZ", personFullName: "Juan Dela Cruz",
      businessSnapshot: { businessName: "Aling Nena's Store (2025)", registeredOwnerName: "Nena Reyes", marketSectionName: "Shoe Avenue" },
    }),
    // Unregistered vendor's ticket.
    row(2, "Ticket", "InProgress", { paperViolatorName: "PEDRO SANTOS", personFullName: "Pedro Santos" }),
    // Warning at a registered business: the confirmed person is the violator.
    row(3, "Warning", null, { ...store, personFullName: "Maria Lopez" }),
    // Older ticket with no name recorded.
    row(4, "Ticket", "Pending"),
  ];
  const html = renderPage({ historyHook: { inspections: rows, total: 4, totalPages: 1 } });
  const cells = tableRows(html).map((r) => [r[0], ...r.slice(2, 8)]);
  assert.deepEqual(cells, [
    ["000451", "JUAN D. CRUZ", "Aling Nena's Store (2025)", "Nena Reyes", "Shoe Avenue", "Ticket", "Overdue"],
    ["000452", "PEDRO SANTOS", "UNREGISTERED", "—", "Dry Goods", "Ticket", "InProgress"],
    ["—", "Maria Lopez", "Aling Nena's Store", "Nena Reyes", "Dry Goods", "Warning", "—"],
    ["000454", "Unconfirmed (legacy record)", "UNREGISTERED", "—", "Dry Goods", "Ticket", "Pending"],
  ]);
  assert.doesNotMatch(html, /Stall No\./);
});

test("every ticket status gets its color, the same as the Tickets table", () => {
  const statuses = ["Pending", "Contested", "InProgress", "Paid", "Cleared", "Overdue", "Waived"];
  const html = renderPage({
    historyHook: { inspections: statuses.map((status, i) => row(i + 1, "Ticket", status)), total: 7, totalPages: 1 },
  });
  for (const [status, tone] of [
    ["Pending", "warning"], ["Contested", "warning"], ["InProgress", "warning"],
    ["Paid", "success"], ["Cleared", "success"], ["Overdue", "danger"], ["Waived", "violet"],
  ])
    assert.match(html, new RegExp(`class="badge ${tone}">${status}<`), status);
});

test("only admins get the Enforcer report button, and only for a real enforcer number", () => {
  assert.match(renderPage(), /Enforcer report/);
  assert.doesNotMatch(renderPage({ isAdmin: false }), /Enforcer report/);
  assert.doesNotMatch(renderPage({ id: "abc" }), /Enforcer report/);
});

test("a loaded page shows the profile, the numbers and the history", () => {
  const html = renderPage();
  assert.match(html, /Cruz, Maria/);
  assert.match(html, /75%/);
  assert.match(html, /33\.3%/);
  assert.match(html, /66\.7% Tickets/);
});

test("a profile that fails to load shows its message and Try again instead of crashing", () => {
  const html = renderPage({ profileHook: { profile: undefined, profileProcess: failed("Enforcer not found.") } });
  assert.match(html, /role="alert"/);
  assert.match(html, /Enforcer not found\./);
  assert.match(html, /Try again/);
});

test("a summary that fails to load shows its message and Try again instead of crashing", () => {
  const html = renderPage({
    performanceHook: { performance: undefined, performanceProcess: failed("Couldn't load the performance summary.") },
  });
  assert.match(html, /Couldn&#x27;t load the performance summary\./);
  assert.match(html, /Try again/);
  assert.doesNotMatch(html, /undefined%/);
});

test("a history list that fails to load says so instead of claiming there are no records", () => {
  const html = renderPage({
    historyHook: { inspections: [], total: 0, totalPages: 1, historyProcess: failed("Couldn't load the inspection history.") },
  });
  assert.match(html, /Couldn&#x27;t load the inspection history\./);
  assert.match(html, /Try again/);
  assert.doesNotMatch(html, /No inspection records found\./);
});

test("a link that is not an enforcer number shows Enforcer not found without crashing", () => {
  for (const id of ["abc", "0", "-3", "1.5"]) {
    const html = renderPage({
      id,
      profileHook: { profile: undefined, profileProcess: idle },
      performanceHook: { performance: undefined, performanceProcess: idle },
      historyHook: { inspections: [], total: 0, totalPages: 1 },
    });
    assert.match(html, /Enforcer not found/, `link ${id}`);
    assert.doesNotMatch(html, /Activity Records/, `link ${id}`);
  }
});

test("an enforcer with no inspections shows zeros and No inspections yet", () => {
  const html = renderPage({
    profileHook: { profile: { ...profile, lastInspectionDate: null }, profileProcess: idle },
    performanceHook: {
      performance: {
        ...performance, totalInspections: 0, resolutionRate: 0, warningRatio: 0, ticketRatio: 0,
        monthlyInspections: performance.monthlyInspections.map((m) => ({ ...m, totalIssuedTickets: 0 })),
      },
      performanceProcess: idle,
    },
    historyHook: { inspections: [], total: 0, totalPages: 1 },
  });
  assert.match(html, /No inspections yet/);
  assert.match(html, /0% Tickets/);
  assert.match(html, /No inspection records found\./);
});

test("the footer counts 10 rows a page", () => {
  assert.match(renderPage(), /Showing 1–10 of 25 entries/);
  const lastPage = renderPage({ historyHook: { page: 3, inspections: tenRows.slice(0, 5) } });
  assert.match(lastPage, /Showing 21–25 of 25 entries/);
});

test("the current page button is shown and marked even past page 3", () => {
  const html = renderPage({ historyHook: { page: 4, total: 50, totalPages: 5 } });
  assert.match(html, /aria-current="page"[^>]*aria-label="Go to page 4"/);
});

test("a warning shows no status; a ticket shows its status", () => {
  const html = renderPage({ historyHook: { inspections: [row(1, "Warning", "Contested"), row(2, "Ticket", "Pending")], total: 2, totalPages: 1 } });
  assert.doesNotMatch(html, /Contested/);
  assert.match(html, /Pending/);
});

test("the history section has its own subtitle", () => {
  const html = renderPage();
  assert.equal(html.match(/Performance summary and inspection log for this enforcer/g)?.length, 1);
});

test("the summary hook only asks the server for a real enforcer number", () => {
  const calls = [];
  const { useFetchPerformance } = load("features/enforcers/hooks/useFetchPerformance.ts", {
    "@/api/endpoints/enforcers.api": { enforcersApi: {} },
    "@tanstack/react-query": {
      useQuery: (options) => {
        calls.push(options.enabled);
        return { data: undefined, isLoading: false, isFetching: false, isError: false, error: null, refetch() {} };
      },
    },
  });
  for (const id of [0, -3, 1.5, Number("abc"), 8]) useFetchPerformance(id);
  assert.deepEqual(calls, [false, false, false, false, true]);
});
