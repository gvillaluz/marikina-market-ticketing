import type { EnforcerRecordCount } from "@/api/types/enforcer.types";
import { formatNumber } from "@/utils/formatters";
import { sharePercent } from "../../enforcerReport.utils";
import styles from "./EnforcerCountRow.module.css";

// Warnings, tickets and total for one violation type, street or day. With totalRecords, also the share
// of all records as a bar and a percentage (the number is always shown, so color is never the only clue).
export default function EnforcerCountRow({
  label,
  counts,
  totalRecords,
  muted = false,
}: {
  label: string;
  counts: EnforcerRecordCount;
  totalRecords?: number;
  muted?: boolean;
}) {
  const share =
    totalRecords === undefined ? null : sharePercent(counts.total, totalRecords);
  return (
    <tr>
      <th scope="row" className={muted ? styles.muted : undefined}>
        {label}
      </th>
      <td>{formatNumber(counts.warnings)}</td>
      <td>{formatNumber(counts.tickets)}</td>
      <td>{formatNumber(counts.total)}</td>
      {share !== null && (
        <td className={styles.shareCell}>
          <span className={styles.track} aria-hidden="true">
            <span className={styles.bar} style={{ width: `${share}%` }} />
          </span>
          <span className={styles.percent}>{share}%</span>
        </td>
      )}
    </tr>
  );
}
