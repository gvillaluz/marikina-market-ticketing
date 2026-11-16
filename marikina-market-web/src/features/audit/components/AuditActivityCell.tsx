import type { AuditLogRecord } from "../audit.types";
import { auditActionLabel } from "../audit.utils";
import SearchHighlight from "@/components/ui/SearchHighlight";
import styles from "./AuditActivityCell.module.css";

export default function AuditActivityCell({
  record,
  search,
}: {
  record: AuditLogRecord;
  search: string;
}) {
  return (
    <div className={styles.activity}>
      <p>
        <SearchHighlight
          text={auditActionLabel(record.action)}
          search={search}
        />
      </p>
      <span>Audit #{record.id}</span>
    </div>
  );
}
