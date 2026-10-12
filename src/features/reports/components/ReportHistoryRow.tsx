import { FileText } from "lucide-react";
import type { ReportHistoryItem } from "@/api/types/reports.types";
import { formatReportRange, formatReportDate } from "../reports.utils";
import ReportTypeBadge from "./ReportTypeBadge";
import styles from "./ReportHistoryRow.module.css";
export default function ReportHistoryRow({
  report,
  onView,
  disabled,
}: {
  report: ReportHistoryItem;
  onView: (id: number) => void;
  disabled: boolean;
}) {
  return (
    <tr className={styles.row}>
      <td>
        <ReportTypeBadge type={report.type} />
      </td>
      <td>{formatReportRange(report.dateRange)}</td>
      <td>{formatReportDate(report.dateGenerated)}</td>
      <td className={styles.actor}>{report.generatedBy.name}</td>
      <td>
        <button
          type="button"
          className={styles.view}
          onClick={() => onView(report.id)}
          disabled={disabled}
          aria-label={`View report ${report.id}`}
        >
          <FileText size={14} aria-hidden="true" />
          View
        </button>
      </td>
    </tr>
  );
}
