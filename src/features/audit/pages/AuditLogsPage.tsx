import { Download } from "lucide-react";
import PageHeader from "@/components/ui/PageHeader/PageHeader";
import Button from "@/components/ui/Button/Button";
import { useAuditLogs } from "../hooks/useAuditLogs";
import AuditOverview from "../components/AuditOverview";
import AuditHistory from "../components/AuditHistory";
import AuditHistoryNotice from "../components/AuditHistoryNotice";
import AuditDetailModal from "../components/AuditDetailModal";
import styles from "./AuditLogsPage.module.css";

export default function AuditLogsPage() {
  const audit = useAuditLogs();
  return (
    <div className={styles.page}>
      <div>
        <p className={styles.context}>Administration</p>
        <PageHeader
          className={styles.header}
          title="Audit Logs"
          subtitle="Review important administrative, security, and record activity across the system."
          actions={
            <Button
              type="button"
              variant="outline"
              size="sm"
              icon={<Download size={15} aria-hidden="true" />}
              className={styles.export}
              disabled={!audit.canExport}
              loading={audit.isExporting}
              onClick={audit.exportLogs}
            >
              {audit.isExporting ? "Exporting…" : "Export Log"}
            </Button>
          }
        />
      </div>
      <AuditOverview model={audit} />
      <AuditHistory model={audit} />
      <AuditHistoryNotice />
      <AuditDetailModal model={audit.detail} />
    </div>
  );
}
