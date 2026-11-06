import assert from 'node:assert/strict';
import { readFile, stat } from 'node:fs/promises';
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
    if (specifier.startsWith('.') || specifier.startsWith('@/')) {
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

const { MemoryRouter } = await import(pathToFileURL(require.resolve('react-router-dom')).href);
const { default: TicketList } = await import(await load(path.join(src, 'features/tickets/components/TicketList.tsx')));
const { InspectionTable } = await import(await load(path.join(src, 'features/inspections/components/InspectionTable.tsx')));

const text = html => html.replace(/<[^>]+>/g, '').replace(/&#x27;/g, "'").trim();
const cells = (html, label) =>
  [...html.matchAll(new RegExp(`<td[^>]*data-label="${label}"[^>]*>([\\s\\S]*?)</td>`, 'g'))].map(m => text(m[1]));
const headers = html => [...html.matchAll(/<th[^>]*>([\s\S]*?)<\/th>/g)].map(m => text(m[1]));

const snapshot = { businessAccountNumber: 'BA-2024-0117', businessName: 'Nena Fresh Fish', registeredOwnerName: 'Nena Dela Cruz', businessType: 'Public', stallNumber: 'F-14', marketSectionName: 'Fish Section', businessAddress: 'Stall F-14, Marikina Public Market' };
const common = { enforcerId: 3, enforcerFirstName: 'Ramon', enforcerLastName: 'Santos', vendorId: 0, vendorFirstName: '', vendorLastName: '', stallNumber: 'F-14', marketSectionId: 2, marketSectionName: 'Fish Section', status: 'Pending', issuedAt: '2026-10-30T02:15:00Z' };
// The current registry owner differs from the ticket-day snapshot to prove the table shows the snapshot.
const ticket = { ...common, id: 41, controlNumber: '000041', paperReference: 'MPM-0041', businessSnapshot: snapshot, paperViolatorName: 'Jun Reyes', registeredOwnerName: 'Later Owner', severity: 'Minor', penaltyType: 'CashFine' };
const legacyTicket = { ...common, id: 7, controlNumber: '000007', paperReference: null, businessSnapshot: null, paperViolatorName: null, registeredOwnerName: null, severity: 'Minor', penaltyType: 'CashFine' };
const unavailable = 'Historical business details unavailable.';

test('ticket list shows business name, registered owner and violator as separate columns', () => {
  const html = renderToStaticMarkup(React.createElement(MemoryRouter, null,
    React.createElement(TicketList, { tickets: [ticket, legacyTicket], onView: () => {} })));
  const shown = headers(html);
  for (const header of ['Business name', 'Registered owner', 'Violator']) assert.ok(shown.includes(header), header);
  assert.ok(!shown.includes('Recorded violator'));
  assert.deepEqual(cells(html, 'Business name'), ['Nena Fresh Fish', unavailable]);
  assert.deepEqual(cells(html, 'Registered owner'), ['Nena Dela Cruz', unavailable]);
  assert.deepEqual(cells(html, 'Violator'), ['Jun Reyes', 'Unconfirmed (legacy record)']);
  assert.deepEqual(cells(html, 'Market section'), ['Fish Section', unavailable]);
});

test('inspection table shows business name, registered owner and violator for tickets and warnings', () => {
  const ticketRow = { ...ticket, ticketId: 41, type: 'Ticket', businessName: 'Current Registry Name' };
  const warningRow = { ...common, ticketId: 52, type: 'Warning', businessSnapshot: null, paperReference: null, personFullName: 'Ana Lopez', registeredOwnerName: 'Pedro Lopez', businessName: 'Lopez Vegetables', marketSectionName: 'Vegetable Section' };
  const legacyRow = { ...legacyTicket, ticketId: 7, type: 'Ticket', businessName: 'Current Registry Name' };
  const html = renderToStaticMarkup(React.createElement(InspectionTable, {
    rows: [ticketRow, warningRow, legacyRow], isLoading: false, isError: false, errorMessage: '', onRetry: () => {}, onView: () => {},
  }));
  const shown = headers(html);
  for (const header of ['Business name', 'Registered owner', 'Violator']) assert.ok(shown.includes(header), header);
  assert.ok(!shown.includes('Trade name') && !shown.includes('Person'));
  assert.deepEqual(cells(html, 'Business name'), ['Nena Fresh Fish', 'Lopez Vegetables', unavailable]);
  assert.deepEqual(cells(html, 'Registered owner'), ['Nena Dela Cruz', 'Pedro Lopez', unavailable]);
  assert.deepEqual(cells(html, 'Violator'), ['Recorded violator: Jun Reyes', 'Confirmed person: Ana Lopez', 'Recorded violator: Unconfirmed (legacy record)']);
});
