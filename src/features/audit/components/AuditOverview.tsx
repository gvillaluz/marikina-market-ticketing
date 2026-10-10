import { History, ShieldCheck, TriangleAlert } from "lucide-react";
import StatCard from "@/components/ui/Card/StatCard/StatCard";
import type { AuditLogsModel } from "../hooks/useAuditLogs";
import styles from "./AuditOverview.module.css";
import AuditRequestMessage from "./AuditRequestMessage";
import AuditStatCardSkeleton from "./AuditStatCardSkeleton";

export default function AuditOverview({ model }: { model: AuditLogsModel }) {
  return (
    <section
      className={styles.overview}
      aria-label="Audit activity counts"
      aria-busy={model.countsLoading}
    >
      {model.countsLoading ? (
        <>
          <AuditStatCardSkeleton />
          <AuditStatCardSkeleton />
          <AuditStatCardSkeleton />
        </>
      ) : (
        <>
          <StatCard
            icon={History}
            iconColor="var(--button-primary)"
            iconBg="var(--button-primary-surface)"
            value={model.counts?.recordedActivities ?? "—"}
            label="Recorded activities"
            note="Across the current review period"
          />
          <StatCard
            icon={ShieldCheck}
            iconColor="var(--success)"
            iconBg="var(--registration-success-surface)"
            value={model.counts?.successfulActions ?? "—"}
            label="Successful actions"
            note="Actions completed successfully"
          />
          <StatCard
            icon={TriangleAlert}
            iconColor="var(--warning)"
            iconBg="var(--registration-warning-surface)"
            value={model.counts?.securityEvents ?? "—"}
            label="Security events"
            note="Successful and failed security records"
          />
        </>
      )}
      {model.countsError && (
        <AuditRequestMessage
          message={model.countsError}
          error
          onRetry={model.retryCounts}
          busy={model.countsLoading}
          className={styles.message}
        />
      )}
    </section>
  );
}
