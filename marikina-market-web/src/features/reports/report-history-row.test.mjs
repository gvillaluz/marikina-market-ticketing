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
function load(relative, cache = new Map()) {
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
        return load(path.relative(root, resolved), cache);
      },
    },
    { filename: file },
  );
  return module.exports;
}

const report = {
  id: 1,
  type: "Warning & Ticket",
  dateRange: { from: "2026-10-01", to: "2026-10-12" },
  dateGenerated: "2026-10-12T05:00:00Z",
  generatedBy: { id: 7, name: "Juan Dela Cruz" },
};
const Row = load("features/reports/components/ReportHistoryRow.tsx").default;
const render = (search) =>
  renderToStaticMarkup(
    React.createElement(Row, {
      report,
      search,
      onView() {},
      disabled: false,
    }),
  );

test("history rows highlight the searched dates, generator and report type", () => {
  const dates = render("oct 12");
  assert.match(
    dates,
    /Oct 1, 2026 – <mark class="mark">Oct 12<\/mark>, 2026/,
  );
  assert.match(dates, /<td><mark class="mark">Oct 12<\/mark>, 2026<\/td>/);
  assert.match(render("dela"), /Juan <mark class="mark">Dela<\/mark> Cruz/);
  assert.match(
    render("WARNING"),
    /<mark class="mark">Warning<\/mark> &amp; Ticket/,
  );
  assert.doesNotMatch(render(""), /<mark/);
});
