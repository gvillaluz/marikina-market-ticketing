import Breadcrumb from "@/components/ui/Breadcrumb";
import { Database } from "lucide-react";

import { ROUTES } from "@/routes/routePaths";
import PageHeader from "@/components/ui/PageHeader";
import { useBackups } from "../hooks/useBackups";
import { useBackupRestore } from "../hooks/useBackupRestore";
import BackupScheduler from "../components/BackupScheduler";
import BackupHealth from "../components/BackupHealth";
import BackupHistory from "../components/BackupHistory";
import RestoreConfirmModal from "../components/RestoreConfirmModal";
import RestoreView from "../components/RestoreView";
import styles from "./BackupsPage.module.css";

export default function BackupsPage() {
  const restore = useBackupRestore();
  const backups = useBackups(restore.isActive);
  return (
    <div className={styles.page}>
      <Breadcrumb
        items={[
          { label: "System Configuration", to: ROUTES.systemConfiguration },
          { label: "Data & Backups" },
        ]}
      />
      {restore.view ? (
        <>
          <PageHeader
            className={styles.header}
            title="Restore a backup"
            subtitle="Today's data is replaced with the backup. Other staff are paused until it ends."
          />
          <RestoreView
            view={restore.view}
            onSignIn={restore.signInAgain}
            onBack={restore.back}
          />
        </>
      ) : (
        <>
          <PageHeader
            className={styles.header}
            title="Data & Backups"
            subtitle="Protect system records with a simple, reliable backup schedule."
            actions={
              <button
                type="button"
                className={styles.backup}
                disabled={!backups.canBackup}
                onClick={backups.backupNow}
              >
                <Database size={15} aria-hidden="true" />
                {backups.isBackingUp ? "Backing Up…" : "Back Up Now"}
              </button>
            }
          />
          <div className={styles.overview}>
            <BackupScheduler schedule={backups.schedule} />
            <BackupHealth health={backups.health} />
          </div>
          <BackupHistory history={backups.history} onRestore={restore.open} />
          <RestoreConfirmModal restore={restore} />
        </>
      )}
    </div>
  );
}
