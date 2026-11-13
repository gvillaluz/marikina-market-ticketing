import assert from 'node:assert/strict';
import { readFile, stat } from 'node:fs/promises';
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath, pathToFileURL } from 'node:url';
import test from 'node:test';
import ts from 'typescript';
import React from 'react';
import { renderToStaticMarkup } from 'react-dom/server';

// Ticket details redesign: the control number shows a "#" (not for a missing number), the status window offers
// only the statuses the ticket may move to, and the change history is a table. Expected values are written by hand.
process.env.TZ = 'Asia/Manila';
const require = createRequire(import.meta.url);
const src = fileURLToPath(new URL('../../', import.meta.url));
const url = source => `data:text/javascript;base64,${Buffer.from(source).toString('base64')}`;
// Outer boundaries only: the portal and the server hook.
const stubs = {
  'react-dom': 'export const createPortal = node => node;',
  '../../hooks/useTicketHistory': 'export const useTicketHistory = () => globalThis.ticketHistory;',
};
const cache = new Map();
async function load(file) {
  if (cache.has(file)) return cache.get(file);
  if (file.endsWith('.css')) return url('export default {};');
  if (!/\.tsx?$/.test(file)) return url('export default "";');
  let source = ts.transpileModule(await readFile(file, 'utf8'), {
    compilerOptions: { module: ts.ModuleKind.ESNext, target: ts.ScriptTarget.ES2020, jsx: ts.JsxEmit.ReactJSX },
    fileName: file,
  }).outputText;
  for (const match of [...source.matchAll(/from\s+["']([^"']+)["']/g)]) {
    const specifier = match[1];
    let target;
    if (stubs[specifier]) target = url(stubs[specifier]);
    else if (specifier.startsWith('.') || specifier.startsWith('@/')) {
      const base = specifier.startsWith('@/') ? path.join(src, specifier.slice(2)) : path.resolve(path.dirname(file), specifier);
      let resolved;
      for (const candidate of [base, `${base}.tsx`, `${base}.ts`, path.join(base, 'index.ts')]) {
        try { if ((await stat(candidate)).isFile()) { resolved = candidate; break; } } catch { /* Try the next source extension. */ }
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
const component = async file => (await import(await load(path.join(src, file)))).default;
globalThis.document = { body: null };
const text = html => html.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ');

const ControlNumber = await component('features/tickets/components/detail/ControlNumber.tsx');
const StatusChangeModal = await component('features/tickets/components/detail/StatusChangeModal.tsx');
const ChangeHistory = await component('features/tickets/components/detail/TicketChangeHistory.tsx');

test('control number shows a "#"; a missing number keeps the legacy text without one', () => {
  assert.equal(text(renderToStaticMarkup(React.createElement(ControlNumber, { value: '000456' }))).trim(), '#000456');
  assert.equal(text(renderToStaticMarkup(React.createElement(ControlNumber, { value: 'WRN-0011' }))).trim(), '#WRN-0011');
  assert.equal(text(renderToStaticMarkup(React.createElement(ControlNumber, { value: null }))).trim(), 'Unavailable (legacy record)');
  assert.equal(text(renderToStaticMarkup(React.createElement(ControlNumber, { value: '  ' }))).trim(), 'Unavailable (legacy record)');
});

const modal = props => renderToStaticMarkup(React.createElement(StatusChangeModal, {
  open: true, controlNumber: '000456', currentStatus: 'Pending', selectedStatus: 'Pending',
  availableStatuses: ['Pending', 'Contested', 'Waived', 'Overdue', 'InProgress'], canUpdate: false, isPending: false,
  onSelect: () => {}, onConfirm: () => {}, onClose: () => {}, ...props,
}));

test('status window never offers Paid or Cleared when they are not available, and stays closed when not open', () => {
  const html = text(modal({}));
  assert.match(html, /Change status/);
  assert.match(html, /Ticket #000456/);
  for (const offered of ['Pending', 'Contested', 'Waived', 'Overdue', 'In Progress']) assert.ok(html.includes(offered), offered);
  assert.ok(!html.includes('Paid'));
  assert.ok(!html.includes('Cleared'));
  assert.equal(modal({ open: false }), '');
});

test('status window offers Paid and Cleared once they are available', () => {
  const html = text(modal({ availableStatuses: ['Pending', 'Paid', 'Cleared'] }));
  assert.ok(html.includes('Paid'));
  assert.ok(html.includes('Cleared'));
});

test('Confirm is off until another status is picked, then the summary says from and to', () => {
  const idle = modal({});
  assert.match(idle, /<button[^>]*disabled[^>]*>(?:(?!<\/button>)[\s\S])*Confirm/);
  assert.match(text(idle), /Select a new status\./);
  const picked = modal({ availableStatuses: ['Pending', 'Paid'], selectedStatus: 'Paid', canUpdate: true });
  assert.doesNotMatch(picked, /<button[^>]*disabled[^>]*>(?:(?!<\/button>)[\s\S])*Confirm/);
  assert.match(text(picked), /Pending → Paid/);
});

test('change history is a table with Action, Details, By and When columns, newest first', () => {
  globalThis.ticketHistory = { entries: [
    { action: 'Status changed', details: 'Status changed from Pending to Paid.', performedBy: 'Maria Dela Cruz', role: 'HeadAdmin', occurredAt: '2026-11-03T02:30:00Z' },
    { action: 'Issued', details: null, performedBy: 'Ana Reyes', role: 'MarketEnforcer', occurredAt: '2026-11-02T01:00:00Z' },
  ], isPending: false, isError: false, isFetching: false, error: null, refetch: () => {} };
  const html = renderToStaticMarkup(React.createElement(ChangeHistory, { ticketId: 5 }));
  assert.deepEqual([...html.matchAll(/<th scope="col">([\s\S]*?)<\/th>/g)].map(m => m[1]), ['Action', 'Details', 'By', 'When']);
  assert.equal([...html.matchAll(/<tbody>[\s\S]*?<\/tbody>/g)].length, 1);
  assert.equal([...html.matchAll(/<tbody>([\s\S]*?)<\/tbody>/g)][0][1].match(/<tr/g).length, 2);
  const flat = text(html);
  assert.ok(flat.indexOf('Status changed') < flat.indexOf('Issued'));
  assert.match(flat, /Maria Dela Cruz \(Head Admin\)/);
  assert.match(flat, /Nov 3, 2026.*10:30/);
});
