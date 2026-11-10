import assert from 'node:assert/strict';
import { readFile, stat } from 'node:fs/promises';
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath, pathToFileURL } from 'node:url';
import test from 'node:test';
import ts from 'typescript';
import React from 'react';
import { renderToStaticMarkup } from 'react-dom/server';

// Warnings have no status. The ticket page shows no status and offers no "Change Status" for a warning,
// even one that still holds an old status from before the server refused changes. Tickets are unchanged.
// Expected values are written by hand.
const require = createRequire(import.meta.url);
const src = fileURLToPath(new URL('../../', import.meta.url));
const url = source => `data:text/javascript;base64,${Buffer.from(source).toString('base64')}`;
// Outer boundaries only: data hooks, the portal, and sections unrelated to the status.
const stubs = {
  'react-dom': 'export const createPortal = node => node;',
  '@/components/ui/TicketModal/modal/TicketPhotoEvidenceSection': 'export default () => null;',
  '../hooks/usePersonTicketHistory': 'export const usePersonTicketHistory = () => globalThis.personHistoryState;',
  '../hooks/useTicketDetails': 'export const useTicketDetails = () => globalThis.detailPageState;',
  '../hooks/useUpdateStatus': 'export const useUpdateStatus = () => ({ mutateAsync: async () => {}, isPending: false });',
  '../components/detail/TicketChangeHistory': 'export default () => null;',
  '../../../components/ui/TicketModal/TicketModal': 'export const TicketModal = () => null;',
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

globalThis.document = { body: null };
const { MemoryRouter } = await import(pathToFileURL(require.resolve('react-router-dom')).href);
const TicketDetailPage = (await import(await load(path.join(src, 'features/tickets/pages/TicketDetailPage.tsx')))).default;
const text = html => html.replace(/<[^>]+>/g, '').replace(/&#x27;/g, "'").trim();

function renderPage(record) {
  globalThis.personHistoryState = { isPending: false, isError: false, items: [], hasNextPage: false };
  globalThis.detailPageState = { ticket: record, refetch: () => {}, isLoading: false, isError: false, error: null };
  return text(renderToStaticMarkup(React.createElement(MemoryRouter, null, React.createElement(TicketDetailPage))));
}
// The words between the header's control number and "Last updated" are the status shown in the header.
const headerStatus = (html, controlNumber) => html.match(new RegExp(`${controlNumber}([A-Za-z ]*)Last updated`))[1];

const detail = { enforcerFirstName: 'Ramon', enforcerLastName: 'Santos', marketSectionName: 'Meat and Poultry',
  issuedAt: '2026-11-08T02:00:00Z', updatedAt: '2026-11-08T02:00:00Z', issuePlace: 'Palengke gate 2', paperViolatorName: 'Juan Cruz',
  businessSnapshot: null, vendorId: null, violations: [], categories: [], description: 'Synthetic', address: '', evidenceItems: [],
  ticketEvidences: [], ticketReceipts: [], proofUrls: [], communityServiceLogs: [], communityServiceHours: null, hoursCompleted: 0,
  personId: null, version: 7 };
const warning = { ...detail, ticketId: 12, type: 'Warning', controlNumber: 'WRN-0012', status: null, penaltyType: null };
const ticket = { ...detail, ticketId: 11, type: 'Ticket', controlNumber: '000456', status: 'Pending', severity: 'Minor', penaltyType: 'CashFine' };

test('a warning shows no status and no Change Status button', () => {
  const html = renderPage(warning);
  assert.equal(headerStatus(html, 'WRN-0012'), '');
  assert.ok(!html.includes('Change Status'));
  assert.ok(html.includes('View Full Ticket Record'));
});

test('a warning that still holds an old status shows no status and no Change Status button', () => {
  const html = renderPage({ ...warning, status: 'Pending' });
  assert.equal(headerStatus(html, 'WRN-0012'), '');
  assert.ok(!html.includes('Change Status'));
});

test('a ticket still shows its status and the Change Status button', () => {
  const html = renderPage(ticket);
  assert.equal(headerStatus(html, '000456'), 'Pending');
  assert.ok(html.includes('Change Status'));
  assert.ok(html.includes('View Full Ticket Record'));
});
