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
  attentionItems: [
    { id: "open-tickets", type: "OpenTickets", title: "Open tickets", count: 4 },
  ],
};

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
  const registrationAlert = {
    ...handWorkedSummary,
    attentionItems: [
      {
        id: "pending-registrations",
        type: "PendingRegistrations",
        title: "Pending registrations",
        count: 1,
      },
    ],
  };
  assert.throws(() => validateDashboardSummary(registrationAlert));
});
