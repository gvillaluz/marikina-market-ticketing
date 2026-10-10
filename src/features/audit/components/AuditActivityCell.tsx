import type { AuditLogRecord } from "../audit.types";
import { auditActionLabel } from "../audit.utils";
import styles from "./AuditActivityCell.module.css";

export default function AuditActivityCell({
  record,
}: {
  record: AuditLogRecord;
}) {
  return (
    <div className={styles.activity}>
      <p>{auditActionLabel(record.action)}</p>
      <span>Audit #{record.id}</span>
    </div>
  );
}
