import { USER_ROLE_LABELS } from "@/api/types/common.types";
import type { AuditLogDetail } from "@/api/types/audit.types";
import {
  auditActionLabel,
  auditActorName,
  formatAuditTimestamp,
} from "../audit.utils";
import AuditResultBadge from "./AuditResultBadge";
import styles from "./AuditDetailContent.module.css";

export default function AuditDetailContent({
  record,
}: {
  record: AuditLogDetail;
}) {
  const fields = [
    { label: "Audit ID", value: String(record.id) },
    {
      label: "Date & time (Asia/Manila)",
      value: formatAuditTimestamp(record.timestamp),
    },
    { label: "Action", value: auditActionLabel(record.action) },
    { label: "Module", value: record.module },
    {
      label: "Performed by",
      value: auditActorName(record),
    },
    {
      label: "Role",
      value:
        record.role === null
          ? "No role recorded"
          : USER_ROLE_LABELS[record.role],
    },
    { label: "Target ID", value: record.targetId ?? "Not recorded" },
  ];
  return (
    <div className={styles.content}>
      <AuditResultBadge result={record.result} />
      <dl className={styles.fields}>
        {fields.map((field) => (
          <div key={field.label}>
            <dt>{field.label}</dt>
            <dd>{field.value}</dd>
          </div>
        ))}
      </dl>
      <section
        className={styles.details}
        aria-labelledby="audit-detail-description"
      >
        <h4 id="audit-detail-description">Details</h4>
        <p>{record.details || "No additional details recorded."}</p>
      </section>
    </div>
  );
}
