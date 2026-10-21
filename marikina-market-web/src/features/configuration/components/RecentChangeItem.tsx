import { FC } from "react";
import { Database, FileText, LayoutGrid } from "lucide-react";
import type { AuditLogSummary } from "@/api/types/audit.types";
import {
  AUDIT_MODULE_OPTIONS,
  AuditResultBadge,
  auditActionLabel,
  auditActorName,
  formatAuditTimestamp,
} from "@/features/audit";
import styles from "./RecentChangeItem.module.css";

interface RecentChangeItemProps {
  record: AuditLogSummary;
}

const RecentChangeItem: FC<RecentChangeItemProps> = ({ record }) => {
  const Icon =
    record.module === "Backups"
      ? Database
      : record.module === "Ordinances"
        ? FileText
        : LayoutGrid;
  const moduleLabel = AUDIT_MODULE_OPTIONS.find(
    (option) => option.value === record.module,
  )?.label;
  return (
    <div className={styles.row}>
      <div className={styles.iconWrap} aria-hidden="true">
        <Icon size={14} strokeWidth={2} />
      </div>
      <div className={styles.text}>
        <span className={styles.title}>{auditActionLabel(record.action)}</span>
        <span className={styles.detail}>
          <span>{moduleLabel}</span>
          <span aria-hidden="true"> · </span>
          <span>{auditActorName(record)}</span>
        </span>
        <AuditResultBadge result={record.result} />
      </div>
      <time className={styles.timestamp} dateTime={record.timestamp}>
        {formatAuditTimestamp(record.timestamp)}
      </time>
    </div>
  );
};

export default RecentChangeItem;
