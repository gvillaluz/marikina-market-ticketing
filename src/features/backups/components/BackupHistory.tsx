import type { BackupHistoryModel } from "../hooks/useBackupHistory";
import BackupHistoryRow from "./BackupHistoryRow";
import BackupMessage from "./BackupMessage";
import styles from "./BackupHistory.module.css";

interface BackupHistoryProps {
  history: BackupHistoryModel;
}

export default function BackupHistory({ history }: BackupHistoryProps) {
  return (
    <section
      className={styles.card}
      aria-labelledby="backup-history-title"
      aria-busy={history.isFetching}
    >
      <header className={styles.header}>
        <h2 id="backup-history-title">Recent Backups</h2>
        <p>Restore points retained by the system.</p>
      </header>
      {history.isError && (
        <BackupMessage
          message={history.error}
          error
          pending={history.isFetching}
          onRetry={history.retry}
        />
      )}
      <div
        className={styles.tableRegion}
        role="region"
        aria-label="Backup history"
        tabIndex={0}
      >
        <table className={styles.table}>
          <thead>
            <tr>
              <th scope="col">Date &amp; Time</th>
              <th scope="col">Type</th>
              <th scope="col">Size</th>
              <th scope="col">Status</th>
              <th scope="col">
                <span className={styles.srOnly}>Actions</span>
              </th>
            </tr>
          </thead>
          <tbody>
            {history.isLoading ? (
              <tr>
                <td colSpan={5}>
                  <BackupMessage message="Loading backup history…" />
                </td>
              </tr>
            ) : history.hasData && history.rows.length === 0 ? (
              <tr>
                <td colSpan={5}>
                  <BackupMessage message="No backups have been recorded yet." />
                </td>
              </tr>
            ) : (
              history.rows.map((backup) => (
                <BackupHistoryRow key={backup.id} backup={backup} />
              ))
            )}
          </tbody>
        </table>
      </div>
      {history.hasPagination && (
        <footer className={styles.footer}>
          <p>
            {history.rows.length > 0
              ? `Showing ${history.offset + 1}–${history.offset + history.rows.length}${history.total != null ? ` of ${history.total}` : ""}`
              : "Backup history"}
          </p>
          <div className={styles.pagination}>
            <button
              type="button"
              disabled={!history.canPrevious}
              onClick={history.previous}
            >
              Previous
            </button>
            <button
              type="button"
              disabled={!history.canNext}
              onClick={history.next}
            >
              Next
            </button>
          </div>
        </footer>
      )}
    </section>
  );
}
