import assert from 'node:assert/strict';
import { readFile, access } from 'node:fs/promises';
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath, pathToFileURL } from 'node:url';
import test from 'node:test';
import ts from 'typescript';
import React from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import { AxiosError } from 'axios';

// Times below are worked out in Manila time, where office staff read them.
process.env.TZ = 'Asia/Manila';

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
    if (specifier.endsWith('useTicketHistory')) {
      // The server is the outer boundary: each test sets the history the hook would return.
      target = url('export const useTicketHistory = () => globalThis.ticketHistory;');
    } else if (specifier === 'lucide-react') {
      target = url('export const History=()=>null; export const RefreshCw=()=>null;');
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
const { default: ChangeHistory } = await import(await load(path.join(src, 'features/tickets/components/detail/TicketChangeHistory.tsx')));
const render = history => {
  globalThis.ticketHistory = { entries: [], isPending: false, isError: false, isFetching: false, error: null, refetch: () => {}, ...history };
  return renderToStaticMarkup(React.createElement(ChangeHistory, { ticketId: 5 }));
};
const text = html => html.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ');

test('entries show in the order the server sends (newest first), with plain names, roles and Manila times', () => {
  const html = text(render({
    entries: [
      { action: 'Status changed', details: 'Status changed from Pending to Contested.', performedBy: 'Juan Dela Cruz', role: 'HeadAdmin', occurredAt: '2026-11-03T02:30:00Z' },
      { action: 'Marked overdue', details: null, performedBy: 'System', role: null, occurredAt: '2026-11-02T16:00:00Z' },
      { action: 'Issued', details: null, performedBy: 'Maria Santos', role: 'MarketEnforcer', occurredAt: '2026-11-02T01:00:00Z' },
    ],
  }));
  assert.match(html, /Change history/i);
  const order = ['Status changed', 'Marked overdue', 'Issued'].map(action => html.indexOf(action));
  assert.deepEqual(order, [...order].sort((a, b) => a - b));
  assert.ok(order.every(index => index >= 0));
  assert.match(html, /Status changed from Pending to Contested\./);
  assert.match(html, /Juan Dela Cruz \(Head Admin\)/);
  assert.match(html, /Maria Santos \(Market Enforcer\)/);
  assert.match(html, /System/);
  assert.doesNotMatch(html, /System \(/);
  // 02:30 UTC on 3 Nov is 10:30 AM in Manila; 16:00 UTC on 2 Nov is midnight on 3 Nov.
  assert.match(html, /Nov 3, 2026.*10:30/);
  assert.match(html, /Nov 3, 2026.*12:00/);
  assert.match(html, /Nov 2, 2026.*9:00/);
});

test('loading, empty and error states use plain messages', () => {
  assert.match(text(render({ isPending: true })), /Loading change history/);
  assert.match(text(render({})), /No recorded changes for this ticket\./);
  const failed = render({ isError: true, error: new AxiosError('Network Error', 'ERR_NETWORK') });
  assert.match(text(failed), /Unable to load the change history\./);
  assert.match(failed, /role="alert"/);
  assert.match(text(failed), /Try again/);
  assert.doesNotMatch(text(failed), /No recorded changes/);
});

test('Try again asks the server again and is disabled while it loads', () => {
  let retried = 0;
  globalThis.ticketHistory = { entries: [], isPending: false, isError: true, isFetching: false, error: null, refetch: () => { retried += 1; } };
  const element = ChangeHistory({ ticketId: 5 });
  const find = node => !node || typeof node !== 'object' ? null
    : node.type === 'button' ? node
      : [node.props?.children].flat(Infinity).map(find).find(Boolean) ?? null;
  find(element).props.onClick();
  assert.equal(retried, 1);
  assert.match(render({ isError: true, isFetching: true }), /<button[^>]*disabled/);
});
