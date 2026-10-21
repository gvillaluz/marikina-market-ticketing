import { USER_ROLE_LABELS } from "@/api/types/common.types";
import type { AuditLogRecord } from "../audit.types";
import styles from "./AuditActorCell.module.css";
import { auditActorName } from "../audit.utils";

export default function AuditActorCell({ record }: { record: AuditLogRecord }) {
  return (
    <div className={styles.actor}>
      <p>{auditActorName(record)}</p>
      <span>
        {record.role === null
          ? "No role recorded"
          : USER_ROLE_LABELS[record.role]}
      </span>
    </div>
  );
}
