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

function renderQuickAccess(role) {
  const { DashboardPage } = load("features/dashboard/pages/DashboardPage.tsx", {
    "@/context/AuthContext": {
      useAuth: () => ({ user: { role, firstName: "Verification" } }),
    },
    "@/features/dashboard/hooks/useDashboardSummary": {
      useDashboardSummary: () => ({
        summary: undefined,
        isLoading: false,
        error: null,
        retry() {},
      }),
    },
    "@/features/dashboard/hooks/useDashboardRegistrationStatus": {
      useDashboardRegistrationStatus: () => ({
        counts: {
          pendingReview: 0,
          needsInformation: 0,
          approved: 0,
          rejected: 0,
        },
        isLoading: false,
        error: null,
        retry() {},
      }),
    },
  });
  const html = renderToStaticMarkup(
    React.createElement(StaticRouter, null, React.createElement(DashboardPage)),
  );
  const quickAccess = html.match(
    /<section[^>]*aria-labelledby="quick-access-title"[^>]*>([\s\S]*?)<\/section>/,
  );
  assert.ok(quickAccess, "Dashboard must render its Quick access section");
  return quickAccess[1];
}

test("AdminOfficer has seven dashboard shortcuts including Configurations and no Staff accounts", () => {
  const html = renderQuickAccess("AdminOfficer");
  const links = [...html.matchAll(/<a\b[^>]*href="([^"]+)"/g)].map(
    (match) => match[1],
  );
  assert.ok(
    links.includes("/system/configuration"),
    "AdminOfficer must have its authorized Configurations shortcut",
  );
  assert.equal(links.length, 7);
  assert.match(html, /7 sections/);
  assert.ok(!links.includes("/admin/accounts"));
});

test("HeadAdmin keeps eight dashboard shortcuts including Configurations and Staff accounts", () => {
  const html = renderQuickAccess("HeadAdmin");
  const links = [...html.matchAll(/<a\b[^>]*href="([^"]+)"/g)].map(
    (match) => match[1],
  );
  assert.equal(links.length, 8);
  assert.match(html, /8 sections/);
  assert.ok(links.includes("/system/configuration"));
  assert.ok(links.includes("/admin/accounts"));
});
