import type { ReportType } from "@/api/types/reports.types";
import SearchHighlight from "@/components/ui/SearchHighlight";
import styles from "./ReportTypeBadge.module.css";
export default function ReportTypeBadge({
  type,
  search,
}: {
  type: ReportType;
  search: string;
}) {
  return (
    <span className={styles.badge}>
      <SearchHighlight text={type} search={search} />
    </span>
  );
}
