import Breadcrumb from "@/components/ui/Breadcrumb";
import { Database } from "lucide-react";

import { ROUTES } from "@/routes/routePaths";
import PageHeader from "@/components/ui/PageHeader";
import { useBackups } from "../hooks/useBackups";
import BackupScheduler from "../components/BackupScheduler";
import BackupHealth from "../components/BackupHealth";
import BackupHistory from "../components/BackupHistory";
import styles from "./BackupsPage.module.css";

export default function BackupsPage() {
  const backups = useBackups();
  return (
    <div className={styles.page}>
      <Breadcrumb
        items={[
          { label: "System Configuration", to: ROUTES.systemConfiguration },
          { label: "Data & Backups" },
        ]}
      />
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
      <BackupHistory history={backups.history} />
    </div>
  );
}
