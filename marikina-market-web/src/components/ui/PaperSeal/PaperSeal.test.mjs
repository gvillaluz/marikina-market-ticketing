import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";
import vm from "node:vm";
import { createRequire } from "node:module";
import React from "react";
import { renderToStaticMarkup } from "react-dom/server";
import ts from "typescript";

// The city seal at the top of the report papers. The papers are drawn with the real code; only
// the picture file is replaced by a fixed name so the page can be read as text.

const require = createRequire(import.meta.url);
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../..");

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

const overrides = {
  "@/assets/icons/Marikina_City_Seal.svg (1).webp": { default: "seal.webp" },
};

const metric = (totalRecords, assessedPenalties) => ({ totalRecords, assessedPenalties });
const summary = {
  total: metric(5, 1500),
  resolved: metric(2, 500),
  pending: metric(3, 1000),
  warningsIssued: metric(2, 0),
  ticketsIssued: metric(3, 1500),
};
const preview = {
  type: "Warning & Ticket",
  dateRange: { from: "2026-11-01", to: "2026-11-15" },
  summary,
};
const saved = {
  ...preview,
  id: 123,
  dateGenerated: "2026-11-16T02:00:00Z",
  generatedBy: { id: 1, name: "Sample Admin" },
};

function reportPaper(report) {
  const ReportPaper = load("features/reports/components/ReportPaper.tsx", overrides).default;
  return renderToStaticMarkup(React.createElement(ReportPaper, { report }));
}

function enforcerPaper() {
  const Frame = load(
    "features/enforcers/components/report/EnforcerReportPaperFrame.tsx",
    overrides,
  ).default;
  return renderToStaticMarkup(
    React.createElement(
      Frame,
      {
        paperRef: { current: null },
        title: "Enforcer performance report",
        meta: [{ term: "Reporting period", value: "Nov 1, 2026" }],
      },
      React.createElement("p", null, "Body"),
    ),
  );
}

function checkSeal(html, titleText) {
  const seals = html.match(/<img[^>]*>/g) ?? [];
  assert.equal(seals.length, 1, "the paper shows exactly one picture, the city seal");
  assert.match(seals[0], /alt="Marikina City seal"/);
  assert.match(seals[0], /src="seal\.webp"/);
  assert.ok(
    html.indexOf(seals[0]) < html.indexOf(titleText),
    "the seal comes before the title, on its left",
  );
  assert.ok(!/>MM</.test(html), "the plain MM circle is gone");
}

test("the report paper shows the city seal before the title, and no MM circle", () => {
  checkSeal(reportPaper(preview), "Marikina Public Market Administration");
});

test("a saved report paper shows the seal too, next to its Report ID", () => {
  const html = reportPaper(saved);
  checkSeal(html, "Marikina Public Market Administration");
  assert.match(html, /MM-000123/);
});

test("both Enforcer report papers share a header that shows the city seal", () => {
  checkSeal(enforcerPaper(), "Marikina Public Market Administration");
});
