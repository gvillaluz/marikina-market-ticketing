import assert from 'node:assert/strict';
import { readFile, stat } from 'node:fs/promises';
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath, pathToFileURL } from 'node:url';
import test from 'node:test';
import ts from 'typescript';
import React from 'react';
import { renderToStaticMarkup } from 'react-dom/server';

// Status by Penalty Type (#161): the real status hook feeds the real Change status window. Expected lists come from
// the table in issue #161, written by hand.
const require = createRequire(import.meta.url);
const src = fileURLToPath(new URL('../../', import.meta.url));
const url = source => `data:text/javascript;base64,${Buffer.from(source).toString('base64')}`;
// Outer boundary only: the portal.
const stubs = { 'react-dom': 'export const createPortal = node => node;' };
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
      if (!resolved) throw new Error(`Unresolved dependency: ${specifier}`);
      target = await load(resolved);
    } else target = pathToFileURL(require.resolve(specifier)).href;
    source = source.replaceAll(JSON.stringify(specifier), JSON.stringify(target))
      .replaceAll(`'${specifier}'`, JSON.stringify(target));
  }
  const result = url(source);
  cache.set(file, result);
  return result;
}
const module = async file => import(await load(path.join(src, file)));
globalThis.document = { body: null };

const StatusChangeModal = (await module('features/tickets/components/detail/StatusChangeModal.tsx')).default;
const { useTicketStatusSelection } = await module('features/tickets/hooks/useTicketStatusSelection.ts');

const Window = ({ ticket }) => {
  const selection = useTicketStatusSelection(ticket);
  return React.createElement(StatusChangeModal, {
    open: true, controlNumber: '000456', currentStatus: ticket.status, selectedStatus: selection.selectedStatus,
    availableStatuses: selection.availableStatuses, canUpdate: selection.canUpdateStatus, isPending: false,
    onSelect: () => {}, onConfirm: () => {}, onClose: () => {},
  });
};
// The option titles, in the order the window shows them.
const offered = ticket => [...renderToStaticMarkup(React.createElement(Window, { ticket }))
  .matchAll(/<button[^>]*aria-pressed[^>]*>[\s\S]*?<\/button>/g)]
  .map(card => card[0].replace(/<[^>]+>/g, '\n').split('\n').map(part => part.trim()).filter(Boolean)[0]);
const ticket = fields => ({ ticketId: 1, controlNumber: '000456', status: 'Pending', version: 3, ...fields });
const settled = {
  CashFine: { proofUrls: ['https://storage.example.com/receipt.jpg'] },
  BloodDonation: { proofUrls: ['https://storage.example.com/receipt.jpg'] },
  CommunityService: { communityServiceHours: 8, hoursCompleted: 8 },
};

for (const [penaltyType, before, after] of [
  ['CashFine', ['Contested', 'Waived'], ['Paid', 'Contested', 'Waived']],
  ['BloodDonation', ['Contested', 'Waived'], ['Contested', 'Waived', 'Cleared']],
  ['CommunityService', ['Contested', 'Waived', 'In Progress'], ['Contested', 'Waived', 'Cleared', 'In Progress']],
]) {
  test(`${penaltyType}: window offers only its statuses, Paid or Cleared only once settlement is possible`, () => {
    assert.deepEqual(offered(ticket({ penaltyType })), before);
    assert.deepEqual(offered(ticket({ penaltyType, ...settled[penaltyType] })), after);
  });

  test(`${penaltyType}: window never offers Pending or Overdue, whatever the current status`, () => {
    for (const status of ['Pending', 'Overdue', 'Paid', 'Cleared', 'Waived', 'InProgress']) {
      const titles = offered(ticket({ penaltyType, status, ...settled[penaltyType] }));
      assert.ok(!titles.includes('Pending') && !titles.includes('Overdue'), `${status}: ${titles}`);
      assert.ok(!titles.includes('Reject contest'), `${status}: ${titles}`);
    }
  });

  test(`${penaltyType}: a Contested ticket also offers Reject contest`, () => {
    assert.deepEqual(offered(ticket({ penaltyType, status: 'Contested' })), ['Reject contest', ...before]);
  });
}
