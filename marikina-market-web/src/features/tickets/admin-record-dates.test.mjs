import assert from 'node:assert/strict';
import { readFile, stat } from 'node:fs/promises';
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath, pathToFileURL } from 'node:url';
import test from 'node:test';
import ts from 'typescript';
import React from 'react';
import { renderToStaticMarkup } from 'react-dom/server';

// Slice B1: a ticket or warning for an unregistered vendor has no business. The server sends the market
// section and the issue place and leaves the business id, name, owner, account number, stall and business
// snapshot empty. Every screen that names a business says "Unregistered vendor" instead, and an old ticket
// whose business details were never saved still says they are unavailable. Expected values are written by hand.
const require = createRequire(import.meta.url);
const src = fileURLToPath(new URL('../../', import.meta.url));
const url = source => `data:text/javascript;base64,${Buffer.from(source).toString('base64')}`;
// Outer boundaries only: data hooks, the portal, and sections unrelated to the vendor.
const stubs = {
  'react-dom': 'export const createPortal = node => node;',
  './modal/TicketSettlementSection': 'export default () => null;',
  './modal/TicketPhotoEvidenceSection': 'export default () => null;',
  '@/components/ui/TicketModal/modal/TicketPhotoEvidenceSection': 'export default () => null;',
  '../hooks/usePersonTicketHistory': 'export const usePersonTicketHistory = () => globalThis.personHistoryState;',
  '../hooks/useTicketDetails': 'export const useTicketDetails = () => globalThis.detailPageState;',
  '../hooks/useTicketStatusSelection': 'export const useTicketStatusSelection = () => ({ selectedStatus: null, setSelectedStatus() {}, availableStatuses: [], canUpdateStatus: false, receiptUrls: [] });',
  '../hooks/useUpdateStatus': 'export const useUpdateStatus = () => ({ mutateAsync: async () => {}, isPending: false });',
  '../components/detail/TicketChangeHistory': 'export default () => null;',
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
    if (specifier === '@/features/tickets') {
      const utils = await load(path.join(src, 'features/tickets/tickets.utils.ts'));
      target = url(`export * from ${JSON.stringify(utils)}; export const useTicketModal = () => globalThis.ticketModalState;`);
    } else if (stubs[specifier]) target = url(stubs[specifier]);
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
const component = async (file, name = 'default') => (await import(await load(path.join(src, file))))[name];

globalThis.document = { body: null };
const { MemoryRouter } = await import(pathToFileURL(require.resolve('react-router-dom')).href);
const render = (type, props) => renderToStaticMarkup(React.createElement(MemoryRouter, null, React.createElement(type, props)));
const text = html => html.replace(/<[^>]+>/g, '').replace(/&#x27;/g, "'").trim();
const cells = (html, label) =>
  [...html.matchAll(new RegExp(`<td[^>]*data-label="${label}"[^>]*>([\\s\\S]*?)</td>`, 'g'))].map(m => text(m[1]));
const headers = html => [...html.matchAll(/<th[^>]*>([\s\S]*?)<\/th>/g)].map(m => text(m[1]));
// Cells of one column, found by header position (works whether or not the table labels its cells).
const column = (html, header) => {
  const index = headers(html).indexOf(header);
  assert.ok(index >= 0, `column "${header}" not found`);
  return [...html.matchAll(/<tr[^>]*>([\s\S]*?)<\/tr>/g)].map(row => [...row[1].matchAll(/<td[^>]*>([\s\S]*?)<\/td>/g)])
    .filter(tds => tds.length > index).map(tds => text(tds[index][1]));
};

const UNREGISTERED = 'Unregistered vendor';
const UNAVAILABLE = 'Historical business details unavailable.';
const DASH = '—';

const base = { enforcerId: 3, enforcerFirstName: 'Ramon', enforcerLastName: 'Santos', marketSectionId: 3, marketSectionName: 'Meat and Poultry',
  status: 'Pending', issuedAt: '2026-11-08T02:00:00Z', issuePlace: 'Palengke gate 2', paperViolatorName: 'Juan Cruz', businessSnapshot: null };
const noBusiness = { vendorId: null, vendorFirstName: null, vendorLastName: null, stallNumber: null, businessName: null, registeredOwnerName: null };
const ticket = { ...base, ...noBusiness, id: 11, ticketId: 11, type: 'Ticket', controlNumber: '000456', paperReference: '000456', severity: 'Minor', penaltyType: 'CashFine' };
const warning = { ...base, ...noBusiness, id: 12, ticketId: 12, type: 'Warning', controlNumber: 'WRN-0012', paperReference: null, personFullName: 'Juan Cruz' };
// An old ticket of a registered business whose snapshot was never saved: still "unavailable", never "unregistered".
const legacy = { ...base, id: 3, ticketId: 3, type: 'Ticket', controlNumber: null, paperReference: null, paperViolatorName: null, marketSectionName: 'Dry Goods',
  vendorId: 10, vendorFirstName: 'Nena', vendorLastName: 'Cruz', stallNumber: '12', businessName: 'Aling Nena', registeredOwnerName: 'Nena Cruz', severity: 'Minor', penaltyType: 'CashFine' };

// Admin record dates: a adminWarning has no due date, so its page must not show "Invalid date";
// every record page shows the real last-updated time. Expected values are written by hand.
// Warning dates: 2026-11-10T02:00:00Z is 10:00 AM in Manila (UTC+8), so it reads "Nov 10, 2026".
const adminWarning = {
  ticketId: 5, type: 'Warning', controlNumber: 'WRN-000005', status: 'Pending', severity: 'Low',
  penaltyType: null, dueDate: null, totalFineAmount: null, violations: [], categories: [], description: 'Test',
  issuedAt: '2026-11-08T02:00:00Z', updatedAt: '2026-11-10T02:00:00Z', marketSectionName: 'Meat and Poultry',
  issuePlace: 'Palengke gate 2', businessSnapshot: null, businessName: null, businessAccountNumber: null,
  stallNumber: null, businessType: null, lastName: null, firstName: null, registeredOwnerName: null,
  personId: null, personFullName: null, paperViolatorName: null, paperReference: null, vendorId: null,
  address: '', enforcerId: 1, enforcerFirstName: 'Ana', enforcerLastName: 'Santos',
  ticketEvidences: [], ticketReceipts: [], evidenceItems: [],
};

test('adminWarning page has no due date line and no "Invalid date"', async () => {
  globalThis.personHistoryState = { isPending: false, isError: false, items: [], hasNextPage: false };
  globalThis.detailPageState = { ticket: adminWarning, refetch: () => {}, isLoading: false, isError: false, error: null };
  globalThis.ticketModalState = { ticket: adminWarning, isLoading: false, isError: false, isTicket: false, ticketPaperRef: null, busyAction: null, exportError: null };
  const html = text(render(await component('features/tickets/pages/TicketDetailPage.tsx'), {}));
  assert.ok(!html.includes('Invalid date'));
  assert.ok(!html.includes('DUE DATE'));
});

test('record page shows the real last-updated time', async () => {
  globalThis.personHistoryState = { isPending: false, isError: false, items: [], hasNextPage: false };
  globalThis.detailPageState = { ticket: adminWarning, refetch: () => {}, isLoading: false, isError: false, error: null };
  globalThis.ticketModalState = { ticket: adminWarning, isLoading: false, isError: false, isTicket: false, ticketPaperRef: null, busyAction: null, exportError: null };
  const html = text(render(await component('features/tickets/pages/TicketDetailPage.tsx'), {}));
  assert.ok(html.includes('Last updated Nov 10, 2026'));
});
