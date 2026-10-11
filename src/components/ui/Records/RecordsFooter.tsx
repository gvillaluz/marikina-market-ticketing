import { Download, Printer } from "lucide-react";
import Pagination from "@/components/ui/Pagination";
import styles from "./RecordsFooter.module.css";

interface RecordsFooterProps {
  page: number;
  pageSize: number;
  total: number;
  totalPages: number;
  rowCount: number;
  label: string;
  busy?: boolean;
  onPageChange: (page: number) => void;
  onExport?: () => void;
  onPrint?: () => void;
}

export function RecordsFooter({
  page,
  pageSize,
  total,
  totalPages,
  rowCount,
  label,
  busy,
  onPageChange,
  onExport,
  onPrint,
}: RecordsFooterProps) {
  return (
    <footer className={styles.footer}>
      <span className={styles.entries}>
        {busy
          ? "Updating records…"
          : `Showing ${rowCount === 0 ? 0 : (page - 1) * pageSize + 1}–${rowCount === 0 ? 0 : Math.min((page - 1) * pageSize + rowCount, total)} of ${total.toLocaleString()} ${label}`}
      </span>
      <div className={styles.controls}>
        {(onExport || onPrint) && (
          <div className={styles.actions}>
            {onExport && (
              <button
                type="button"
                onClick={onExport}
                disabled={busy || total === 0}
              >
                <Download size={14} strokeWidth={1.8} aria-hidden="true" />
                Export
              </button>
            )}
            {onPrint && (
              <button
                type="button"
                onClick={onPrint}
                disabled={busy || total === 0}
                className={styles.print}
                aria-label={`Print ${label}`}
                title={`Print ${label}`}
              >
                <Printer size={15} strokeWidth={1.8} aria-hidden="true" />
              </button>
            )}
          </div>
        )}
        <Pagination
          page={page}
          totalPages={totalPages}
          onChange={onPageChange}
          compact
          showSinglePage
          disabled={busy}
          visiblePages={3}
          className={styles.pagination}
        />
      </div>
    </footer>
  );
}
