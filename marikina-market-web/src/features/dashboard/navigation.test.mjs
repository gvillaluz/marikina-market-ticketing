import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";
import test from "node:test";
import vm from "node:vm";
import React from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { StaticRouter } from "react-router-dom/server.js";
import ts from "typescript";

const require = createRequire(import.meta.url);
const root = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  "../..",
);

function load(relative, overrides, cache = new Map()) {
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
        ].find(
          (candidate) =>
            fs.existsSync(candidate) && fs.statSync(candidate).isFile(),
        );
        assert.ok(resolved, `Cannot resolve ${id}`);
        const alias = `@/${path
          .relative(root, resolved)
          .replaceAll("\\", "/")
          .replace(/\.tsx?$/, "")}`;
        if (alias in overrides)
          return { __esModule: true, ...overrides[alias] };
        return load(path.relative(root, resolved), overrides, cache);
      },
    },
    { filename: file },
  );
  return module.exports;
}

// Hand-worked example from the slice 3a plan: today 2 warnings and 3 tickets
// (paid, waiting, contested); earlier a waiting, an overdue and a cleared
// ticket; 3 active businesses and 1 inactive.
const handWorkedSummary = {
  asOf: "2026-11-07T06:00:00Z",
  metrics: {
    warningsToday: 2,
    ticketsToday: 3,
    openTickets: 4,
    activeBusinesses: 3,
  },
  recentActivity: [],
  overdueTickets: { total: 0, items: [] },
};

// Hand-worked overdue example from the plan: on 24 Nov 2026 seven tickets are
// overdue; the server sends the five that have waited longest, oldest first.
const overdueSummary = {
  ...handWorkedSummary,
  overdueTickets: {
    total: 7,
    items: [
      { id: 1, controlNumber: "2026-000391", vendorId: 1, businessName: "Synthetic Fruit Stand", daysOverdue: 14 },
      { id: 2, controlNumber: "2026-000402", vendorId: null, businessName: null, daysOverdue: 10 },
      { id: 3, controlNumber: "2026-000410", vendorId: 3, businessName: null, daysOverdue: 7 },
      { id: 4, controlNumber: null, vendorId: 4, businessName: "Synthetic Meat Shop", daysOverdue: 1 },
      { id: 5, controlNumber: "2026-000425", vendorId: 5, businessName: "Synthetic Rice Center", daysOverdue: 0 },
    ],
  },
};

function attentionPanel(html) {
  const panel = html.match(
    /<h2>Needs attention<\/h2>([\s\S]*?)<\/article>/,
  );
  assert.ok(panel, "Dashboard must render its Needs attention panel");
  return panel[1];
}

function renderDashboard(role, summary) {
  const { DashboardPage } = load("features/dashboard/pages/DashboardPage.tsx", {
    "@/context/AuthContext": {
      useAuth: () => ({ user: { role, firstName: "Verification" } }),
    },
    "@/features/dashboard/hooks/useDashboardSummary": {
      useDashboardSummary: () => ({
        summary,
        isLoading: false,
        error: null,
        retry() {},
      }),
    },
  });
  return renderToStaticMarkup(
    React.createElement(StaticRouter, null, React.createElement(DashboardPage)),
  );
}

function renderQuickAccess(role) {
  const html = renderDashboard(role, undefined);
  const quickAccess = html.match(
    /<section[^>]*aria-labelledby="quick-access-title"[^>]*>([\s\S]*?)<\/section>/,
  );
  assert.ok(quickAccess, "Dashboard must render its Quick access section");
  return quickAccess[1];
}

test("AdminOfficer has six dashboard shortcuts including Configurations and no Staff accounts", () => {
  const html = renderQuickAccess("AdminOfficer");
  const links = [...html.matchAll(/<a\b[^>]*href="([^"]+)"/g)].map(
    (match) => match[1],
  );
  assert.ok(
    links.includes("/system/configuration"),
    "AdminOfficer must have its authorized Configurations shortcut",
  );
  assert.equal(links.length, 6);
  assert.match(html, /6 sections/);
  assert.ok(!links.includes("/admin/accounts"));
});

test("HeadAdmin keeps seven dashboard shortcuts including Configurations and Staff accounts", () => {
  const html = renderQuickAccess("HeadAdmin");
  const links = [...html.matchAll(/<a\b[^>]*href="([^"]+)"/g)].map(
    (match) => match[1],
  );
  assert.equal(links.length, 7);
  assert.match(html, /7 sections/);
  assert.ok(links.includes("/system/configuration"));
  assert.ok(links.includes("/admin/accounts"));
});

test("dashboard shortcuts lead to Businesses and never to vendor registrations", () => {
  const html = renderQuickAccess("HeadAdmin");
  assert.match(
    html,
    /href="\/admin\/vendors"[\s\S]*?Businesses[\s\S]*?Manage business records/,
  );
  assert.doesNotMatch(
    html,
    /vendor-registrations|Vendor registrations|Vendor directory/,
  );
});

test("dashboard counters show the hand-worked totals with warnings and tickets apart", () => {
  const html = renderDashboard("AdminOfficer", handWorkedSummary);
  assert.match(html, /aria-label="Warnings today: 2"/);
  assert.match(html, /aria-label="Tickets today: 3"/);
  assert.match(html, /aria-label="Open tickets: 4"/);
  assert.match(html, /aria-label="Active businesses: 3"/);
  assert.doesNotMatch(
    html,
    /Inspections today|Active vendors|Pending applications/,
  );
  assert.doesNotMatch(html, /Registration pipeline/);
});

test("dashboard data check accepts the new counters and refuses the old ones", () => {
  const { validateDashboardSummary } = load(
    "features/dashboard/dashboard.validation.ts",
    {},
  );
  assert.doesNotThrow(() => validateDashboardSummary(handWorkedSummary));
  const oldShape = {
    ...handWorkedSummary,
    metrics: {
      inspectionsToday: 5,
      openTickets: 4,
      activeVendors: 3,
      pendingRegistrations: 1,
    },
  };
  assert.throws(() => validateDashboardSummary(oldShape));
  const { overdueTickets: _overdue, ...withoutOverdue } = handWorkedSummary;
  const openTicketsAlert = {
    ...withoutOverdue,
    attentionItems: [
      { id: "open-tickets", type: "OpenTickets", title: "Open tickets", count: 4 },
    ],
  };
  assert.throws(() => validateDashboardSummary(openTicketsAlert));
});

test("Needs attention lists the overdue tickets in the order the server sends them", () => {
  const panel = attentionPanel(renderDashboard("AdminOfficer", overdueSummary));
  const lines = [...panel.matchAll(/<a\b[^>]*href="([^"]+)"[^>]*>([\s\S]*?)<\/a>/g)];
  assert.deepEqual(
    lines.map((line) => line[1]),
    ["/tickets/1", "/tickets/2", "/tickets/3", "/tickets/4", "/tickets/5", "/tickets?status=Overdue"],
  );
  const text = lines.map((line) => line[2].replace(/<[^>]+>/g, " ").replace(/\s+/g, " ").trim());
  assert.equal(text[0], "Synthetic Fruit Stand #2026-000391 14 days overdue");
  assert.equal(text[1], "Unregistered #2026-000402 10 days overdue");
  assert.equal(text[2], "Historical business details unavailable. #2026-000410 7 days overdue");
  assert.equal(text[3], "Synthetic Meat Shop Unavailable (legacy record) 1 day overdue");
  assert.equal(text[4], "Synthetic Rice Center #2026-000425 Overdue since today");
  assert.equal(text[5], "Go to Tickets");
  assert.match(panel, /Showing 5 of 7 overdue tickets/);
  assert.doesNotMatch(panel, /Open tickets/);
});

test("Needs attention hides the Showing line when every overdue ticket is listed", () => {
  const summary = {
    ...overdueSummary,
    overdueTickets: { total: 5, items: overdueSummary.overdueTickets.items },
  };
  const panel = attentionPanel(renderDashboard("AdminOfficer", summary));
  assert.doesNotMatch(panel, /Showing/);
  assert.match(panel, /href="\/tickets\?status=Overdue"[^>]*>Go to Tickets</);
});

test("Needs attention says nothing is overdue and keeps the Go to Tickets button", () => {
  const panel = attentionPanel(renderDashboard("AdminOfficer", handWorkedSummary));
  assert.match(panel, /No overdue tickets/);
  assert.match(panel, /Every open ticket is still within its 5-day settlement period\./);
  assert.match(panel, /href="\/tickets\?status=Overdue"[^>]*>Go to Tickets</);
  assert.doesNotMatch(panel, /href="\/tickets\/\d/);
});

test("Needs attention shows neither lines nor the button while loading or after an error", () => {
  for (const state of [
    { isLoading: true, error: null },
    { isLoading: false, error: "Unable to load the dashboard summary. Please try again." },
  ]) {
    const { DashboardPage } = load("features/dashboard/pages/DashboardPage.tsx", {
      "@/context/AuthContext": {
        useAuth: () => ({ user: { role: "AdminOfficer", firstName: "Verification" } }),
      },
      "@/features/dashboard/hooks/useDashboardSummary": {
        // A refresh keeps the last summary while it loads again.
        useDashboardSummary: () => ({ summary: overdueSummary, ...state, retry() {} }),
      },
    });
    const panel = attentionPanel(
      renderToStaticMarkup(
        React.createElement(StaticRouter, null, React.createElement(DashboardPage)),
      ),
    );
    assert.doesNotMatch(panel, /Go to Tickets|Showing/);
  }
});

test("dashboard data check refuses damaged overdue lists", () => {
  const { validateDashboardSummary } = load(
    "features/dashboard/dashboard.validation.ts",
    {},
  );
  assert.doesNotThrow(() => validateDashboardSummary(overdueSummary));
  const items = overdueSummary.overdueTickets.items;
  const damaged = [
    { total: 7, items: [...items, { ...items[0], id: 6 }] }, // more than five lines
    { total: 4, items }, // fewer in total than listed
    { total: 7, items: [{ ...items[0], daysOverdue: -1 }] },
    { total: 7, items: [{ ...items[0], daysOverdue: 1.5 }] },
    { total: 7, items: [{ ...items[0], id: 0 }] },
    { total: 7, items: [{ ...items[0], vendorId: "1" }] },
    { total: 7, items: [{ ...items[0], businessName: 12 }] },
    { total: 7, items: [{ ...items[0], controlNumber: 391 }] },
    { total: -1, items: [] },
  ];
  for (const overdueTickets of damaged)
    assert.throws(() =>
      validateDashboardSummary({ ...overdueSummary, overdueTickets }),
    );
});

function renderTicketFilterStatus(url) {
  // Build-time settings (Vite's import.meta.env) are an outer boundary here.
  const { useTicketFilters } = load("features/tickets/hooks/useTicketFilters.ts", {
    "@/config/env": { default: { apiBaseUrl: "/api" } },
  });
  function Probe() {
    return React.createElement("output", null, useTicketFilters().filters.status);
  }
  return renderToStaticMarkup(
    React.createElement(StaticRouter, { location: url }, React.createElement(Probe)),
  );
}

test("the Tickets page starts on Overdue only when the link asks for it", () => {
  assert.equal(renderTicketFilterStatus("/tickets?status=Overdue"), "<output>Overdue</output>");
  assert.equal(renderTicketFilterStatus("/tickets"), "<output>All Status</output>");
  assert.equal(renderTicketFilterStatus("/tickets?status=Hacked"), "<output>All Status</output>");
  assert.equal(renderTicketFilterStatus("/tickets?status=overdue"), "<output>All Status</output>");
});
