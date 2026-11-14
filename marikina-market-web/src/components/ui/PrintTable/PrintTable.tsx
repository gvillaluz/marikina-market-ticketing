import type { RefObject } from "react";
import type { ExportColumn } from "@/utils/tableExport";
import { formatDateTime } from "@/utils/formatters";
import styles from "./PrintTable.module.css";

export interface PrintTableProps<T> {
  contentRef: RefObject<HTMLDivElement>;
  title: string;
  columns: ExportColumn<T>[];
  rows: T[] | null;
}

// Hidden on screen; the print window copies only the inner sheet.
export function PrintTable<T>({
  contentRef,
  title,
  columns,
  rows,
}: PrintTableProps<T>) {
  if (!rows) return null;
  return (
    <div className={styles.hidden} aria-hidden="true">
      <div ref={contentRef} className={styles.sheet}>
        <h1 className={styles.title}>{title}</h1>
        <p className={styles.meta}>
          {rows.length.toLocaleString()} records · Printed{" "}
          {formatDateTime(new Date())}
        </p>
        <table className={styles.table}>
          <thead>
            <tr>
              {columns.map((column) => (
                <th key={column.key} scope="col">
                  {column.header}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {rows.map((row, index) => (
              <tr key={index}>
                {columns.map((column) => (
                  <td key={column.key}>{column.value(row)}</td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
