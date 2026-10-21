import type { RefObject } from "react";
import type { ReportDocument } from "@/api/types/reports.types";
import {
  formatReportRange,
  formatReportDate,
  reportSummaryRows,
} from "../reports.utils";
import ReportSummaryRow from "./ReportSummaryRow";
import styles from "./ReportPaper.module.css";

export default function ReportPaper({
  report,
  paperRef,
}: {
  report: ReportDocument;
  paperRef?: RefObject<HTMLElement>;
}) {
  const saved = "id" in report;
  return (
    <article
      ref={paperRef}
      className={styles.paper}
      aria-label={
        saved ? `Saved report ${report.id}` : "Unsaved report preview"
      }
    >
      <header className={styles.header}>
        <span className={styles.mark} aria-hidden="true">
          MM
        </span>
        <div className={styles.heading}>
          <p>Official inspection report</p>
          <h3>Marikina Public Market Administration</h3>
          <h4>Inspection &amp; Enforcement Summary Report</h4>
        </div>
        <div className={styles.reference}>
          <span>{saved ? "Report ID" : "Preview"}</span>
          <strong>
            {saved ? `MM-${String(report.id).padStart(6, "0")}` : "Unsaved"}
          </strong>
        </div>
      </header>
      <dl className={styles.meta}>
        <div>
          <dt>Reporting period</dt>
          <dd>{formatReportRange(report.dateRange)}</dd>
        </div>
        <div>
          <dt>Report type</dt>
          <dd>{report.type}</dd>
        </div>
        {saved && (
          <div>
            <dt>Date generated</dt>
            <dd>{formatReportDate(report.dateGenerated)}</dd>
          </div>
        )}
      </dl>
      <section
        className={styles.summary}
        aria-labelledby="report-summary-title"
      >
        <h4 id="report-summary-title">Summary of records</h4>
        <div className={styles.tableWrap}>
          <table className={styles.table}>
            <thead>
              <tr>
                <th scope="col">Summary</th>
                <th scope="col">Total Records</th>
                <th scope="col">Assessed Penalties</th>
              </tr>
            </thead>
            <tbody>
              {reportSummaryRows(report).map((row) => (
                <ReportSummaryRow key={row.label} row={row} />
              ))}
            </tbody>
          </table>
        </div>
        {report.summary.total.totalRecords === 0 && (
          <p className={styles.empty}>
            No records were found for this reporting period.
          </p>
        )}
      </section>
      <div className={styles.signatures}>
        <div>
          <p>Prepared by</p>
          <strong>{saved ? report.generatedBy.name : "Unsaved preview"}</strong>
          <span>Name and signature of preparer</span>
        </div>
        <div>
          <p>Reviewed by</p>
          <span className={styles.signatureLine} />
          <span>Name and signature</span>
        </div>
      </div>
      <footer className={styles.footer}>
        <span>Dates inclusive · Asia/Manila</span>
        <span>
          {saved
            ? "Saved report · Original totals preserved"
            : "Preview · Generate to save this report"}
        </span>
        <span>Page 1 of 1</span>
      </footer>
    </article>
  );
}
