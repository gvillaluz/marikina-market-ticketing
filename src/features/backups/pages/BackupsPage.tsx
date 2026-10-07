import { ChevronRight, Database } from "lucide-react";
import { Link } from "react-router-dom";
import { ROUTES } from "@/routes/routePaths";
import { useBackups } from "../hooks/useBackups";
import BackupScheduler from "../components/BackupScheduler";
import BackupHealth from "../components/BackupHealth";
import BackupHistory from "../components/BackupHistory";
import BackupMessage from "../components/BackupMessage";
import styles from "./BackupsPage.module.css";

export default function BackupsPage() {
  const backups = useBackups();
  return (
    <div className={styles.page}>
      <nav className={styles.breadcrumb} aria-label="Breadcrumb">
        <Link to={ROUTES.systemConfiguration}>System Configuration</Link>
        <ChevronRight size={12} aria-hidden="true" />
        <span aria-current="page">Data &amp; Backups</span>
      </nav>
      <header className={styles.header}>
        <div>
          <h1>Data &amp; Backups</h1>
          <p>Protect system records with a simple, reliable backup schedule.</p>
        </div>
        <button
          type="button"
          className={styles.backup}
          disabled={!backups.canBackup}
          onClick={backups.backupNow}
        >
          <Database size={15} aria-hidden="true" />
          {backups.isBackingUp ? "Backing Up…" : "Back Up Now"}
        </button>
      </header>
      {backups.manualError && (
        <BackupMessage message={backups.manualError} error />
      )}
      {backups.manualSuccess && (
        <BackupMessage
          message={backups.manualSuccess}
          error={backups.manualFailed}
        />
      )}
      <div className={styles.overview}>
        <BackupScheduler schedule={backups.schedule} />
        <BackupHealth health={backups.health} />
      </div>
      <BackupHistory history={backups.history} />
    </div>
  );
}
