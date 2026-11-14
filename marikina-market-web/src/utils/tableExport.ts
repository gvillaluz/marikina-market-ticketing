export interface ExportColumn<T> {
  key: string;
  header: string;
  value: (row: T) => string;
}

export interface RowPage<T> {
  items: T[];
  hasMore: boolean;
}

// Collects every page of a list, starting each request where the last one ended.
export async function fetchAllRows<T>(
  fetchPage: (offset: number) => Promise<RowPage<T>>,
): Promise<T[]> {
  const rows: T[] = [];
  for (;;) {
    const page = await fetchPage(rows.length);
    rows.push(...page.items);
    if (!page.hasMore || page.items.length === 0) return rows;
  }
}

// Quotes a cell, and stops spreadsheet programs from running text as a formula.
function csvCell(value: string): string {
  const text = /^[=+\-@\t\r]/.test(value) ? `'${value}` : value;
  return `"${text.replace(/"/g, '""')}"`;
}

export function toCsv<T>(columns: ExportColumn<T>[], rows: T[]): string {
  return [
    columns.map((column) => column.header),
    ...rows.map((row) => columns.map((column) => column.value(row))),
  ]
    .map((line) => line.map(csvCell).join(","))
    .join("\r\n");
}

export function downloadCsv<T>(
  fileName: string,
  columns: ExportColumn<T>[],
  rows: T[],
): void {
  const url = URL.createObjectURL(
    new Blob(["﻿", toCsv(columns, rows)], {
      type: "text/csv;charset=utf-8",
    }),
  );
  const link = document.createElement("a");
  link.href = url;
  link.download = fileName;
  document.body.appendChild(link);
  link.click();
  link.remove();
  window.setTimeout(() => URL.revokeObjectURL(url), 1000);
}

// The calendar day a record was issued, in Philippine time (YYYY-MM-DD).
export function manilaDay(value: string | Date): string {
  const date = new Date(value);
  if (!Number.isFinite(date.getTime())) return "";
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Manila",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(date);
}
