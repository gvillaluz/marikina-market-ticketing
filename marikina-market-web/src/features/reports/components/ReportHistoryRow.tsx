import { FileText } from "lucide-react";
import Button from "@/components/ui/Button";
import SearchHighlight from "@/components/ui/SearchHighlight";
import type { ReportHistoryItem } from "@/api/types/reports.types";
import { formatReportRange, formatReportDate } from "../reports.utils";
import ReportTypeBadge from "./ReportTypeBadge";
import styles from "./ReportHistoryRow.module.css";
export default function ReportHistoryRow({
  report,
  search,
  onView,
  disabled,
}: {
  report: ReportHistoryItem;
  search: string;
  onView: (id: number) => void;
  disabled: boolean;
}) {
  return (
    <tr>
      <td>
        <ReportTypeBadge type={report.type} search={search} />
      </td>
      <td>
        <SearchHighlight
          text={formatReportRange(report.dateRange)}
          search={search}
        />
      </td>
      <td>
        <SearchHighlight
          text={formatReportDate(report.dateGenerated)}
          search={search}
        />
      </td>
      <td className={styles.actor}>
        <SearchHighlight text={report.generatedBy.name} search={search} />
      </td>
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
