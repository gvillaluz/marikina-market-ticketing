import { Download, RotateCcw } from "lucide-react";
import type { BackupHistoryRowModel } from "../hooks/useBackupHistory";
import styles from "./BackupHistoryRow.module.css";

interface BackupHistoryRowProps {
  backup: BackupHistoryRowModel;
}

export default function BackupHistoryRow({ backup }: BackupHistoryRowProps) {
  return (
    <tr className={styles.row}>
      <td className={styles.date}>{backup.dateLabel}</td>
      <td>{backup.type}</td>
      <td>{backup.sizeLabel}</td>
      <td>
        <div className={styles.statusContent}>
          <span
            className={`${styles.badge} ${backup.status === "Failed" ? styles.failed : styles.completed}`}
          >
            <span aria-hidden="true" />
            {backup.status}
          </span>
          {backup.status === "Failed" && backup.errorMessage && (
            <p className={styles.error}>{backup.errorMessage}</p>
          )}
        </div>
      </td>
      <td className={styles.actionCell}>
        <div className={styles.actions}>
          <button
            type="button"
            className={styles.download}
            disabled
            title="Downloads are currently unavailable"
          >
            <Download size={12} aria-hidden="true" />
            Download
          </button>
          <button
            type="button"
            className={styles.restore}
            disabled
            title="Restores are currently unavailable"
          >
            <RotateCcw size={12} aria-hidden="true" />
            Restore
          </button>
        </div>
      </td>
    </tr>
  );
}
