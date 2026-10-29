import assert from 'node:assert/strict';
import { readFile, access } from 'node:fs/promises';
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath, pathToFileURL } from 'node:url';
import test from 'node:test';
import ts from 'typescript';
import React from 'react';
import { renderToStaticMarkup } from 'react-dom/server';

const require = createRequire(import.meta.url);
const src = fileURLToPath(new URL('../../', import.meta.url));
const url = source => `data:text/javascript;base64,${Buffer.from(source).toString('base64')}`;
const cache = new Map();
async function load(file) {
  if (cache.has(file)) return cache.get(file);
  if (file.endsWith('.css')) return url('export default {};');
  let source = ts.transpileModule(await readFile(file, 'utf8'), {
    compilerOptions: { module: ts.ModuleKind.ESNext, target: ts.ScriptTarget.ES2020, jsx: ts.JsxEmit.ReactJSX },
    fileName: file,
  }).outputText;
  for (const match of [...source.matchAll(/from\s+["']([^"']+)["']/g)]) {
    const specifier = match[1];
    let target;
    if (specifier === 'lucide-react') {
      target = url('export const FileWarning=()=>null; export const History=()=>null;');
    } else if (specifier.startsWith('.') || specifier.startsWith('@/')) {
      const base = specifier.startsWith('@/') ? path.join(src, specifier.slice(2)) : path.resolve(path.dirname(file), specifier);
      let resolved;
      for (const candidate of [base, `${base}.tsx`, `${base}.ts`]) {
        try { await access(candidate); resolved = candidate; break; } catch { /* Try the next source extension. */ }
      }
      if (!resolved) throw new Error(`Unresolved component dependency: ${specifier}`);
      target = await load(resolved);
    } else target = pathToFileURL(require.resolve(specifier)).href;
    source = source.replaceAll(JSON.stringify(specifier), JSON.stringify(target))
      .replaceAll(`'${specifier}'`, JSON.stringify(target));
  }
  const result = url(source);
  cache.set(file, result);
  return result;
}
const { default: Details } = await import(await load(path.join(src, 'components/ui/TicketModal/modal/TicketViolationDetailsSection.tsx')));
const record = { type: 'Ticket', violations: [], categories: [], issuedAt: '2026-10-29T08:00:00Z',
  marketSectionName: 'Fish section', description: 'Synthetic citation', paperReference: '000456', issuePlace: 'Fish aisle near F-014' };

test('real ticket detail rows preserve printed reference and written place separately from section', () => {
  const html = renderToStaticMarkup(React.createElement(Details, { detail: record }));
  assert.match(html, /PAPER REFERENCE/);
  assert.match(html, /000456/);
  assert.match(html, /ISSUE PLACE/);
  assert.match(html, /Fish aisle near F-014/);
  assert.match(html, /Fish section/);
});

test('legacy ticket detail explicitly leaves paper reference and place unavailable', () => {
  const html = renderToStaticMarkup(React.createElement(Details, { detail: { ...record, paperReference: null, issuePlace: null } }));
  assert.equal((html.match(/Unavailable \(legacy record\)/g) || []).length, 2);
  assert.doesNotMatch(html, /000456|Fish aisle near F-014/);
});
