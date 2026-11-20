import type { EnforcerReportRow } from "@/api/types/enforcer.types";
import { formatCurrency, formatNumber } from "@/utils/formatters";
import { formatManilaDate } from "../../enforcerReport.utils";
import EnforcerReportHeading from "./EnforcerReportHeading";
import styles from "./EnforcerSummaryTiles.module.css";

export default function EnforcerSummaryTiles({
  row,
}: {
  row: EnforcerReportRow;
}) {
  const tiles = [
    { label: "Warnings", value: formatNumber(row.warnings) },
    { label: "Tickets", value: formatNumber(row.tickets) },
    { label: "Total records", value: formatNumber(row.totalRecords) },
    { label: "Settled tickets", value: formatNumber(row.settledTickets) },
    { label: "Open tickets", value: formatNumber(row.openTickets) },
    { label: "Days with records", value: formatNumber(row.daysWithRecords) },
    { label: "Fines charged", value: formatCurrency(row.finesCharged) },
    { label: "Fines settled", value: formatCurrency(row.finesSettled) },
    {
      label: "Last record",
      value: row.lastRecordAt ? formatManilaDate(row.lastRecordAt) : "—",
    },
  ];
  return (
    <section className={styles.section} aria-labelledby="enforcer-summary-title">
      <EnforcerReportHeading id="enforcer-summary-title">
        Summary
      </EnforcerReportHeading>
      <dl className={styles.tiles}>
        {tiles.map((tile) => (
          <div key={tile.label} className={styles.tile}>
            <dt>{tile.label}</dt>
            <dd>{tile.value}</dd>
          </div>
        ))}
      </dl>
    </section>
  );
}
