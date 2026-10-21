import Button from "@/components/ui/Button/Button";
import type { AuditLogRecord } from "../audit.types";
import styles from "./AuditViewButton.module.css";

export default function AuditViewButton({
  record,
  onView,
}: {
  record: AuditLogRecord;
  onView: (record: AuditLogRecord) => void;
}) {
  return (
    <Button
      type="button"
      variant="outline"
      size="sm"
      className={styles.button}
      aria-label={`View audit log ${record.id}`}
      onClick={() => onView(record)}
    >
      View
    </Button>
  );
}
