import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";
import test from "node:test";
import vm from "node:vm";
import { randomUUID } from "node:crypto";
import React from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { MemoryRouter } from "react-router-dom";
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
      crypto: { randomUUID },
      require(id) {
        if (id in overrides) return { __esModule: true, ...overrides[id] };
        if (id.endsWith(".css"))
          return {
            __esModule: true,
            default: new Proxy({}, { get: (_, key) => key }),
          };
        if (id.endsWith(".webp"))
          return { __esModule: true, default: "fixture.webp" };
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

const state = {
  isLoading: false,
  isError: false,
  errorMessage: "Unavailable",
  onRetry() {},
};
function render(name, props) {
  const Component = load(`features/analytics/components/${name}.tsx`).default;
  return renderToStaticMarkup(
    React.createElement(Component, { ...state, ...props }),
  );
}

test("category counts identify category matches rather than unique tickets and zero data has a neutral chart", () => {
  const html = render("ViolationTypeDistribution", {
    data: [
      { category: "Sanitation", ticketCount: 2, percentage: 66.7 },
      { category: "Licensing", ticketCount: 2, percentage: 66.7 },
    ],
  });
  assert.match(html, /<strong>4<\/strong>\s*<span>Category matches<\/span>/);
  assert.match(html, /ticket can have multiple categories/i);
  assert.match(html, /50%/); // The donut's shares are of the four category matches.
  const empty = render("ViolationTypeDistribution", {
    data: [{ category: "Sanitation", ticketCount: 0, percentage: 0 }],
  });
  assert.match(empty, /conic-gradient\(#e8edf3 0% 100%\)/);
});

test("resolution card does not label late-resolved tickets as remaining cases", () => {
  const html = render("ResolutionRateCard", {
    data: { ticketCount: 3, resolvedWithinSevenDays: 1, resolutionRate: 33.3 },
  });
  assert.match(html, /Other tickets/);
  assert.doesNotMatch(html, /Remaining/);
  assert.match(html, /<strong>2<\/strong>/);
});

test("analytics panels show loading during a retry even when cached data exists", () => {
  const { useAdminAnalyticsPage } = load(
    "features/analytics/hooks/useAdminAnalyticsPage.ts",
    {
      "@/api/client": { default: {} },
      "@tanstack/react-query": {
        useQuery: () => ({
          data: [],
          isLoading: false,
          isFetching: true,
          isError: true,
          refetch() {},
        }),
      },
    },
  );
  assert.ok(
    Object.values(useAdminAnalyticsPage()).every((panel) => panel.isLoading),
  );
});
