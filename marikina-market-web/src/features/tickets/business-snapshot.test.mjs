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
      target = url('export const User=()=>null;');
    } else if (specifier.startsWith('.') || specifier.startsWith('@/')) {
      if (specifier === '@/features/tickets') { target = await load(path.join(src, 'features/tickets/tickets.utils.ts')); } else {
      const base = specifier.startsWith('@/') ? path.join(src, specifier.slice(2)) : path.resolve(path.dirname(file), specifier);
      let resolved;
      for (const candidate of [base, `${base}.tsx`, `${base}.ts`]) {
        try { await access(candidate); resolved = candidate; break; } catch { /* Try the next source extension. */ }
      }
      if (!resolved) throw new Error(`Unresolved component dependency: ${specifier}`);
      target = await load(resolved);
      }
    } else target = pathToFileURL(require.resolve(specifier)).href;
    source = source.replaceAll(JSON.stringify(specifier), JSON.stringify(target))
      .replaceAll(`'${specifier}'`, JSON.stringify(target));
  }
  const result = url(source);
  cache.set(file, result);
  return result;
}
const { default: Details } = await import(await load(path.join(src, 'components/ui/TicketModal/modal/TicketViolatorInfoSection.tsx')));
const snapshot = {businessAccountNumber:'SNAP-001',businessName:'Fish A',registeredOwnerName:'Owner A',businessType:'Public',stallNumber:'F-14',marketSectionName:'Fish A section',businessAddress:'14 Market Lane'};
const record = {type:'Ticket', businessName:'Current B',registeredOwnerName:'Owner B',businessAccountNumber:'CURRENT-B',businessType:'Public',address:'Current address B'};
test('saved business fields use the snapshot after registry changes', () => {
  const html = renderToStaticMarkup(React.createElement(Details,{detail:{...record,businessSnapshot:snapshot}}));
  for (const value of Object.values(snapshot)) assert.ok(html.includes(value), value);
  assert.doesNotMatch(html,/Current B|Owner B|CURRENT-B|Current address B/);
});
test('legacy citation explicitly leaves historical data unavailable', () => {
  const html = renderToStaticMarkup(React.createElement(Details,{detail:record}));
  assert.match(html,/Historical business details unavailable/);
  assert.doesNotMatch(html,/Current B|Owner B|CURRENT-B|Current address B/);
});
