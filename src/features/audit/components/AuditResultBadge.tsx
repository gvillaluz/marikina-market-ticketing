import { Badge } from "@/components/ui/Badge/Badge";
import type { AuditLogRecord } from "../audit.types";
import styles from "./AuditResultBadge.module.css";

export default function AuditResultBadge({
  result,
}: {
  result: AuditLogRecord["result"];
}) {
  return (
    <Badge
      tone={result === "Success" ? "success" : "warning"}
      className={styles.badge}
    >
      <span className={styles.dot} aria-hidden="true" />
      {result}
    </Badge>
  );
}
