import type { RefObject } from "react";
import type { EnforcerReport } from "@/api/types/enforcer.types";
import { formatCurrency, formatNumber } from "@/utils/formatters";
import { formatReportPeriod } from "../../enforcerReport.utils";
import EnforcerReportRow from "./EnforcerReportRow";
import styles from "./EnforcerReportPaper.module.css";

const COLUMNS = [
  "Warnings",
  "Tickets",
  "Total records",
  "Settled tickets",
  "Open tickets",
  "Fines charged",
  "Fines settled",
  "Days with records",
  "Last record",
];

export default function EnforcerReportPaper({
  report,
  paperRef,
}: {
  report: EnforcerReport;
  paperRef: RefObject<HTMLElement>;
}) {
  const { totals } = report;
  return (
    <article
      ref={paperRef}
      className={styles.paper}
      aria-label="Enforcer activity report"
    >
      <header className={styles.header}>
        <span className={styles.mark} aria-hidden="true">
          MM
        </span>
        <div>
          <h3>Marikina Public Market Administration</h3>
          <p>Enforcer Activity Report</p>
        </div>
      </header>
      <dl className={styles.meta}>
        <div>
          <dt>Reporting period</dt>
          <dd>{formatReportPeriod(report.dateRange)}</dd>
        </div>
        <div>
          <dt>Enforcers listed</dt>
          <dd>{formatNumber(report.enforcers.length)}</dd>
        </div>
      </dl>
      <div
        className={styles.tableWrap}
        tabIndex={0}
        role="region"
        aria-label="Enforcer report table"
      >
        <table className={styles.table}>
          <thead>
            <tr>
              <th scope="col">Enforcer</th>
              {COLUMNS.map((column) => (
                <th key={column} scope="col">
                  {column}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {report.enforcers.map((row) => (
              <EnforcerReportRow key={row.enforcerId} row={row} />
            ))}
          </tbody>
          <tfoot>
            <tr>
              <th scope="row">Total</th>
              <td>{formatNumber(totals.warnings)}</td>
              <td>{formatNumber(totals.tickets)}</td>
              <td>{formatNumber(totals.totalRecords)}</td>
              <td>{formatNumber(totals.settledTickets)}</td>
              <td>{formatNumber(totals.openTickets)}</td>
              <td>{formatCurrency(totals.finesCharged)}</td>
              <td>{formatCurrency(totals.finesSettled)}</td>
              <td />
              <td />
            </tr>
          </tfoot>
        </table>
      </div>
      {totals.totalRecords === 0 && (
        <p className={styles.empty}>
          No warnings or tickets were recorded in this period.
        </p>
      )}
      <div className={styles.signatures}>
        <div>
          <span className={styles.signatureLine} />
          <span>Prepared by (name and signature)</span>
        </div>
        <div>
          <span className={styles.signatureLine} />
          <span>Reviewed by (name and signature)</span>
        </div>
      </div>
      <footer className={styles.footer}>
        <span>Dates inclusive · Philippine time</span>
        <span>Settled tickets are paid, cleared or waived</span>
      </footer>
    </article>
  );
}
