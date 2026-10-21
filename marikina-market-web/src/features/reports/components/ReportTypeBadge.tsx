import type { ReportType } from "@/api/types/reports.types";
import styles from "./ReportTypeBadge.module.css";
export default function ReportTypeBadge({ type }: { type: ReportType }) {
  return <span className={styles.badge}>{type}</span>;
}
