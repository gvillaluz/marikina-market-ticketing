import type { RefObject } from "react";
import type { EnforcerReport } from "@/api/types/enforcer.types";
import { formatCurrency, formatNumber } from "@/utils/formatters";
import { formatReportPeriod } from "../../enforcerReport.utils";
import EnforcerReportPaperFrame from "./EnforcerReportPaperFrame";
import EnforcerReportTable from "./EnforcerReportTable";
import EnforcerReportRow from "./EnforcerReportRow";
import styles from "./EnforcerReportPaper.module.css";

const COLUMNS = [
  "Enforcer",
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
    <EnforcerReportPaperFrame
      paperRef={paperRef}
      title="Enforcer Activity Report"
      meta={[
        { term: "Reporting period", value: formatReportPeriod(report.dateRange) },
        { term: "Enforcers listed", value: formatNumber(report.enforcers.length) },
      ]}
    >
      <EnforcerReportTable
        label="Enforcer report table"
        columns={COLUMNS}
        wide
        foot={
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
        }
      >
        {report.enforcers.map((row) => (
          <EnforcerReportRow key={row.enforcerId} row={row} />
        ))}
      </EnforcerReportTable>
      {totals.totalRecords === 0 && (
        <p className={styles.empty}>
          No warnings or tickets were recorded in this period.
        </p>
      )}
    </EnforcerReportPaperFrame>
  );
}
