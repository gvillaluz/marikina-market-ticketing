import { FileText } from "lucide-react";
import Button from "@/components/ui/Button";
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
    <tr>
      <td>
        <ReportTypeBadge type={report.type} />
      </td>
      <td>{formatReportRange(report.dateRange)}</td>
      <td>{formatReportDate(report.dateGenerated)}</td>
      <td className={styles.actor}>{report.generatedBy.name}</td>
      <td>
        <Button
          type="button"
          variant="outline"
          size="sm"
          className={styles.view}
          onClick={() => onView(report.id)}
          disabled={disabled}
          aria-label={`View report ${report.id}`}
          icon={<FileText size={14} aria-hidden="true" />}
        >
          View
        </Button>
      </td>
    </tr>
  );
}
