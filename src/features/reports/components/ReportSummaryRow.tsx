import type { ReportMetric } from "@/api/types/reports.types";
import { reportCurrency } from "../reports.utils";
import styles from "./ReportSummaryRow.module.css";
export default function ReportSummaryRow({
  row,
}: {
  row: ReportMetric & { label: string };
}) {
  const total = row.label === "Total";
  return (
    <tr className={total ? styles.total : styles.row}>
      <th scope="row">{row.label}</th>
      <td>{row.totalRecords.toLocaleString("en-PH")}</td>
      <td>{reportCurrency.format(row.assessedPenalties)}</td>
    </tr>
  );
}
