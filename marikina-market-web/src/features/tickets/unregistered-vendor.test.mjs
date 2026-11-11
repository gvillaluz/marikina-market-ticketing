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

test("tickets list names the unregistered vendor and uses the ticket's own market section", async () => {
  const html = render(await component('features/tickets/components/TicketList.tsx'), { tickets: [ticket, legacy], onView: () => {} });
  assert.deepEqual(cells(html, 'Business name'), [UNREGISTERED, UNAVAILABLE]);
  assert.deepEqual(cells(html, 'Registered owner'), [DASH, UNAVAILABLE]);
  assert.deepEqual(cells(html, 'Market section'), ['Meat and Poultry', UNAVAILABLE]);
  assert.deepEqual(cells(html, 'Violator'), ['Juan Cruz', 'Unconfirmed (legacy record)']);
});

test('inspections list names the unregistered vendor for tickets and warnings', async () => {
  const html = render(await component('features/inspections/components/InspectionTable.tsx', 'InspectionTable'), {
    rows: [ticket, warning, legacy], isLoading: false, isError: false, errorMessage: '', onRetry: () => {}, onView: () => {} });
  assert.deepEqual(cells(html, 'Business name'), [UNREGISTERED, UNREGISTERED, UNAVAILABLE]);
  assert.deepEqual(cells(html, 'Registered owner'), [DASH, DASH, UNAVAILABLE]);
  assert.deepEqual(cells(html, 'Market section'), ['Meat and Poultry', 'Meat and Poultry', UNAVAILABLE]);
});

const detail = { ...ticket, violations: [], categories: [], description: 'Synthetic', lastName: null, firstName: null, businessAccountNumber: null,
  businessType: null, address: '', evidenceItems: [], ticketEvidences: [], personId: 31, personFullName: 'Juan Cruz' };

test('record popup shows the unregistered vendor and no business rows', async () => {
  const TicketModal = await component('components/ui/TicketModal/TicketModal.tsx', 'TicketModal');
  for (const record of [detail, { ...detail, ...warning, lastName: null, firstName: null }]) {
    globalThis.ticketModalState = { ticket: record, isLoading: false, isError: false, isTicket: record.type === 'Ticket', ticketPaperRef: null, busyAction: null, exportError: null };
    const html = text(render(TicketModal, { isOpen: true, ticketId: record.ticketId, onClose: () => {} }));
    assert.ok(html.includes(`VENDOR:${UNREGISTERED}`), record.type);
    assert.ok(html.includes('Meat and Poultry'), record.type);
    assert.ok(!html.includes(UNAVAILABLE), record.type);
    assert.ok(!html.includes('BUSINESS ID:') && !html.includes('TRADE NAME:') && !html.includes('REGISTERED OWNER:'), record.type);
  }
});

test('ticket page shows the unregistered vendor, its market section and place', async () => {
  globalThis.personHistoryState = { isPending: false, isError: false, items: [], hasNextPage: false };
  globalThis.detailPageState = { ticket: detail, refetch: () => {}, isLoading: false, isError: false, error: null };
  globalThis.ticketModalState = { ticket: detail, isLoading: false, isError: false, isTicket: true, ticketPaperRef: null, busyAction: null, exportError: null };
  const html = text(render(await component('features/tickets/pages/TicketDetailPage.tsx'), {}));
  assert.ok(html.includes(`VENDOR${UNREGISTERED}`));
  assert.ok(html.includes('MARKET SECTIONMeat and Poultry'));
  assert.ok(html.includes('ISSUE PLACEPalengke gate 2'));
  assert.ok(!html.includes(UNAVAILABLE));
  assert.ok(!html.includes('BUSINESS ACCOUNT NUMBER') && !html.includes('BUSINESS NAME') && !html.includes('REGISTERED OWNER'));
});

test('person history names an unregistered vendor and still flags an old record', async () => {
  const item = { ticketId: 11, paperReference: '000456', controlNumber: '5', issuePlace: 'Palengke gate 2', paperViolatorName: 'Juan Cruz', ordinances: [],
    issuedAt: '2026-11-08T02:00:00Z', status: 'Pending', enforcerName: 'Santos', assessedCashFine: null, outstandingCashFine: 0,
    businessName: null, registeredOwnerName: null, businessSnapshot: null };
  globalThis.personHistoryState = { isPending: false, isError: false, items: [item, { ...item, ticketId: 3, paperReference: '000300', businessName: 'Aling Nena' }], hasNextPage: false };
  const html = text(render(await component('features/tickets/components/PersonTicketHistory.tsx'), { personId: 31 }));
  assert.ok(html.includes(`Control number000456Pending${UNREGISTERED}`));
  assert.ok(html.includes(`Control number000300Pending${UNAVAILABLE}`));
});

test('pending settlements name an unregistered vendor and show its market section', async () => {
  const Settlement = await component('features/vendors/components/compliance/SettlementCard.tsx');
  const html = text(render(Settlement, { settlement: { ticketId: 11, controlNumber: '000456', businessAccountNumber: null, vendorName: null,
    marketSectionName: 'Meat and Poultry', status: 'Pending', penaltyType: 'CashFine', totalPaymentAmount: 100, communityServiceHours: null,
    issuedAt: '2026-11-08T02:00:00Z', dueDate: '2026-11-13T02:00:00Z' } }));
  assert.ok(html.includes(`${UNREGISTERED} · 000456`));
  assert.ok(html.includes('Meat and Poultry'));
  assert.doesNotMatch(html, /null|undefined/);
});

test('community service log names an unregistered vendor and has no account number', async () => {
  const logs = [{ ticketId: 11, controlNumber: '000456', businessAccountNumber: null, vendorName: null, completedHours: 2, totalHours: 8,
    lastUpdated: '2026-11-08T02:00:00Z', proofDocumentCount: 0, status: 'Pending' }];
  const html = render(await component('features/vendors/components/AdminCommunityServiceLogs.tsx'), {
    logs, page: 1, setPage: () => {}, status: 'all', setStatus: () => {}, totalLabel: 1, offset: 0, totalPages: 1, hasMore: false,
    isLoading: false, isError: false, errorMessage: '', refetch: () => {}, getProgressStatus: () => 'pending' });
  assert.deepEqual(column(html, 'Vendor Name'), [UNREGISTERED]);
  assert.deepEqual(column(html, 'Business Account Number'), [DASH]);
  assert.match(html, /Unregistered vendor community service hours completed/);
  assert.doesNotMatch(text(html), /null|undefined/);
});

test('enforcer inspection list shows the unregistered section and no owner or stall', async () => {
  const html = render(await component('features/enforcers/components/performance/EnforcerInspectionList.tsx'), { records: [ticket, warning], onView: () => {} });
  assert.deepEqual(column(html, 'Registered owner'), [DASH, DASH]);
  assert.deepEqual(column(html, 'Stall No.'), [DASH, DASH]);
  assert.deepEqual(column(html, 'Section'), ['Meat and Poultry', 'Meat and Poultry']);
});
