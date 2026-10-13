import Pagination from "@/components/ui/Pagination";
import RegistryTable from "@/components/ui/RegistryTable";
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
      {history.downloadError && (
        <BackupMessage message={history.downloadError} error />
      )}
      <RegistryTable
        className={styles.table}
        ariaLabel="Backup history"
        labelledBy="backup-history-title"
        busy={history.isFetching}
        columns={[
          { label: "Date & Time", className: styles.dateColumn },
          { label: "Type", className: styles.typeColumn },
          { label: "Size", className: styles.sizeColumn },
          { label: "Status" },
          { label: "Actions", className: styles.actionColumn, hidden: true },
        ]}
      >
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
            <BackupHistoryRow
              key={backup.id}
              backup={backup}
              onDownload={() => history.download(backup)}
            />
          ))
        )}
      </RegistryTable>
      {(history.hasData || history.page > 1) && (
        <footer className={styles.footer}>
          <p role="status">{history.rangeLabel}</p>
          <fieldset
            className={styles.paginationControls}
            disabled={history.isFetching}
            aria-label="Backup history pages"
          >
            <Pagination
              compact
              showSinglePage
              page={history.page}
              totalPages={history.totalPages}
              canGoNext={!history.canNext}
              onChange={history.changePage}
              className={styles.pagination}
            />
          </fieldset>
        </footer>
      )}
    </section>
  );
}
