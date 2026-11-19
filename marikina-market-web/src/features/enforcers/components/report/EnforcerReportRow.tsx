import type { EnforcerReportRow as ReportRow } from "@/api/types/enforcer.types";
import { formatCurrency, formatNumber } from "@/utils/formatters";
import { formatManilaDate } from "../../enforcerReport.utils";
import styles from "./EnforcerReportRow.module.css";

function countCell(value: number) {
  return (
    <td className={value === 0 ? styles.zero : undefined}>
      {formatNumber(value)}
    </td>
  );
}

export default function EnforcerReportRow({ row }: { row: ReportRow }) {
  return (
    <tr className={styles.row}>
      <th scope="row" className={styles.name}>
        <span className={styles.fullName}>
          {row.lastName}, {row.firstName}
        </span>
        <span className={styles.username}>
          {row.username}
          {row.status === "Inactive" && (
            <span className={styles.inactive}>Inactive</span>
          )}
        </span>
      </th>
      {countCell(row.warnings)}
      {countCell(row.tickets)}
      {countCell(row.totalRecords)}
      {countCell(row.settledTickets)}
      {countCell(row.openTickets)}
      <td className={row.finesCharged === 0 ? styles.zero : undefined}>
        {formatCurrency(row.finesCharged)}
      </td>
      <td className={row.finesSettled === 0 ? styles.zero : undefined}>
        {formatCurrency(row.finesSettled)}
      </td>
      {countCell(row.daysWithRecords)}
      <td className={row.lastRecordAt ? undefined : styles.zero}>
        {row.lastRecordAt ? formatManilaDate(row.lastRecordAt) : "—"}
      </td>
    </tr>
  );
}
