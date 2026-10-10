import { ShieldCheck } from "lucide-react";
import styles from "./AuditHistoryNotice.module.css";

export default function AuditHistoryNotice() {
  return (
    <aside className={styles.notice}>
      <span className={styles.icon}>
        <ShieldCheck size={18} aria-hidden="true" />
      </span>
      <div>
        <h2>Protected audit history</h2>
        <p>
          Review system activity for accountability and incident investigation.
          Records cannot be edited or deleted from this page.
        </p>
      </div>
    </aside>
  );
}
