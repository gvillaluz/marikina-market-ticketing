import assert from 'node:assert/strict';
import { readFile, stat } from 'node:fs/promises';
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath, pathToFileURL } from 'node:url';
import test from 'node:test';
import ts from 'typescript';
import React from 'react';
import { renderToStaticMarkup } from 'react-dom/server';

// Control number Part 2: every website screen shows the control number the server sends
// (printed number for a ticket, WRN number for a warning) and "Unavailable (legacy record)"
// for an old ticket without a printed number. Expected values are written by hand.
const require = createRequire(import.meta.url);
const src = fileURLToPath(new URL('../../', import.meta.url));
const url = source => `data:text/javascript;base64,${Buffer.from(source).toString('base64')}`;
// Outer boundaries only: data hooks, the portal, and sections unrelated to the number.
const stubs = {
  'react-dom': 'export const createPortal = node => node;',
  './modal/TicketSettlementSection': 'export default () => null;',
  './modal/TicketPhotoEvidenceSection': 'export default () => null;',
  '../hooks/usePersonTicketHistory': 'export const usePersonTicketHistory = () => globalThis.personHistoryState;',
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
const LEGACY = 'Unavailable (legacy record)';
const OLD_LABELS = /CTRL #|System #|SYSTEM CONTROL|System control|Paper reference|PAPER REFERENCE|WARNING REFERENCE/;

const common = { enforcerId: 3, enforcerFirstName: 'Ramon', enforcerLastName: 'Santos', vendorId: 10, vendorFirstName: 'Nena', vendorLastName: 'Cruz',
  stallNumber: '12', marketSectionId: 1, marketSectionName: 'Dry Goods', status: 'Pending', issuedAt: '2026-11-01T02:00:00Z', businessSnapshot: null };
const ticket = { ...common, id: 1, ticketId: 1, type: 'Ticket', controlNumber: '000456', paperReference: '000456', severity: 'Minor', penaltyType: 'CashFine' };
const warning = { ...common, id: 2, ticketId: 2, type: 'Warning', controlNumber: 'WRN-0011', paperReference: null };
const legacy = { ...common, id: 3, ticketId: 3, type: 'Ticket', controlNumber: null, paperReference: null, severity: 'Minor', penaltyType: 'CashFine' };

test('tickets list has one control number column', async () => {
  const html = render(await component('features/tickets/components/TicketList.tsx'), { tickets: [ticket, legacy], onView: () => {} });
  assert.ok(headers(html).includes('Control number'));
  assert.deepEqual(cells(html, 'Control number'), ['000456', LEGACY]);
  assert.doesNotMatch(html, OLD_LABELS);
});

test('inspections list shows the control number for tickets and warnings', async () => {
  const html = render(await component('features/inspections/components/InspectionTable.tsx', 'InspectionTable'), {
    rows: [ticket, warning, legacy], isLoading: false, isError: false, errorMessage: '', onRetry: () => {}, onView: () => {} });
  assert.deepEqual(cells(html, 'Control number'), ['000456', 'WRN-0011', LEGACY]);
  assert.doesNotMatch(html, OLD_LABELS);
});

const detail = { ...ticket, violations: [], categories: [], description: 'Synthetic', issuePlace: 'Stall 12', lastName: 'Cruz', firstName: 'Nena',
  businessName: 'Aling Nena', businessAccountNumber: 'ACC-100', businessType: 'Public', address: '', evidenceItems: [], ticketEvidences: [] };

test('record popup shows one control number box for tickets, warnings and old tickets', async () => {
  const TicketModal = await component('components/ui/TicketModal/TicketModal.tsx', 'TicketModal');
  for (const [record, number] of [[detail, '000456'], [{ ...detail, ...warning }, 'WRN-0011'], [{ ...detail, ...legacy }, LEGACY]]) {
    globalThis.ticketModalState = { ticket: record, isLoading: false, isError: false, isTicket: record.type === 'Ticket', ticketPaperRef: null, busyAction: null, exportError: null };
    const html = render(TicketModal, { isOpen: true, ticketId: record.ticketId, onClose: () => {} });
    assert.equal((html.match(/CONTROL NO\./g) || []).length, 1);
    assert.ok(text(html).includes(`CONTROL NO.${number}`), number);
    assert.doesNotMatch(html, OLD_LABELS);
  }
});

test('ticket detail header shows the control number', async () => {
  const Header = await component('features/tickets/components/detail/TicketDetailHeader.tsx');
  assert.match(text(render(Header, { controlNo: '000456', status: 'Pending', lastUpdated: '' })), /^#000456/);
  assert.match(text(render(Header, { controlNo: null, status: 'Pending', lastUpdated: '' })), /^Unavailable \(legacy record\)/);
});

test('person history shows "Control number" only', async () => {
  const item = { ticketId: 1, paperReference: '000456', controlNumber: '7', issuePlace: 'Stall 12', paperViolatorName: 'Juan', ordinances: [], issuedAt: '2026-11-01T02:00:00Z',
    status: 'Pending', enforcerName: 'Santos', assessedCashFine: null, outstandingCashFine: 0, businessSnapshot: null };
  globalThis.personHistoryState = { isPending: false, isError: false, items: [item, { ...item, ticketId: 3, paperReference: null, controlNumber: '8' }], hasNextPage: false };
  const html = text(render(await component('features/tickets/components/PersonTicketHistory.tsx'), { personId: 1 }));
  assert.match(html, /Control number#000456/);
  assert.match(html, /Control numberUnavailable \(legacy record\)/);
  assert.doesNotMatch(html, OLD_LABELS);
});

test('compliance activity and pending settlements show the control number', async () => {
  const Activity = await component('features/vendors/components/compliance/ComplianceActivityRow.tsx');
  const Settlement = await component('features/vendors/components/compliance/SettlementCard.tsx');
  const base = { businessAccountNumber: 'ACC-100', vendorName: 'Cruz, Nena', issuedAt: '2026-11-01T02:00:00Z' };
  for (const [row, number] of [[{ ...ticket, ...base }, '000456'], [{ ...warning, ...base }, 'WRN-0011'], [{ ...legacy, ...base }, LEGACY]])
    assert.ok(text(render(Activity, { activity: row })).includes(`ACC-100 · ${number}`), number);
  for (const [row, number] of [[{ ...ticket, ...base }, '000456'], [{ ...legacy, ...base }, LEGACY]]) {
    const html = text(render(Settlement, { settlement: { ...row, dueDate: '2026-11-06T02:00:00Z', totalPaymentAmount: 100, communityServiceHours: null } }));
    assert.ok(html.includes(`ACC-100 · ${number}`), number);
    assert.doesNotMatch(html, OLD_LABELS);
  }
});

test('enforcer inspection list shows the control number', async () => {
  const html = render(await component('features/enforcers/components/performance/EnforcerInspectionList.tsx'), { records: [ticket, warning, legacy], onView: () => {} });
  assert.deepEqual(column(html, 'Control number'), ['000456', 'WRN-0011', LEGACY]);
  assert.doesNotMatch(html, OLD_LABELS);
});

test('community service log shows the control number', async () => {
  const logs = [{ ...ticket, completedHours: 2, totalHours: 8, lastUpdated: '2026-11-01T02:00:00Z', proofDocumentCount: 0 },
    { ...legacy, completedHours: 0, totalHours: 8, lastUpdated: '2026-11-01T02:00:00Z', proofDocumentCount: 0 }]
    .map(log => ({ ...log, businessAccountNumber: 'ACC-100', vendorName: 'Cruz, Nena' }));
  const html = render(await component('features/vendors/components/AdminCommunityServiceLogs.tsx'), {
    logs, page: 1, setPage: () => {}, status: 'all', setStatus: () => {}, totalLabel: 2, offset: 0, totalPages: 1, hasMore: false,
    isLoading: false, isError: false, errorMessage: '', refetch: () => {}, getProgressStatus: () => 'pending' });
  assert.deepEqual(column(html, 'Control number'), ['000456', LEGACY]);
  assert.doesNotMatch(html, OLD_LABELS);
});

test('business inspection history shows the control number for tickets and warnings', async () => {
  const rows = [ticket, warning, legacy].map(row => ({ ...row, ordinanceNumbers: [], enforcerName: 'Santos' }));
  const html = render(await component('features/vendors/components/AdminVendorInspectionHistory.tsx'), {
    search: '', onSearchChange: () => {}, type: 'all', onTypeChange: () => {}, sortDirection: 'desc', onSortDirectionChange: () => {},
    page: 1, totalPages: 1, onPageChange: () => {}, inspections: rows, total: 3, hasMore: false, isLoading: false, isFetching: false,
    isError: false, errorMessage: '', onRetry: () => {}, onExport: () => {}, onPrint: () => {}, onView: () => {} });
  assert.deepEqual(column(html, 'CONTROL NUMBER').map(cell => cell.split('Historical')[0]), ['000456', 'WRN-0011', LEGACY]);
  assert.doesNotMatch(html, /N\/A|CTRL #/);
});
