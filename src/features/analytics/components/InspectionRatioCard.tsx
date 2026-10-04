import type { InspectionRatio } from "@/api/types/admin-analytics.types";
import AnalyticsPanel from "./AnalyticsPanel";
import styles from "./AnalyticsSummaryCards.module.css";

interface InspectionRatioCardProps {
  data?: InspectionRatio;
  isLoading: boolean;
  isError: boolean;
  errorMessage: string;
  onRetry: () => void;
}

export default function InspectionRatioCard({
  data,
  isLoading,
  isError,
  errorMessage,
  onRetry,
}: InspectionRatioCardProps) {
  return (
    <AnalyticsPanel
      title="Inspection Ratio"
      skeletonVariant="summary"
      isLoading={isLoading}
      isError={isError}
      errorMessage={errorMessage}
      onRetry={onRetry}
      className={styles.smallPanel}
    >
      {data && (
        <div className={styles.ratioContent}>
          <div className={styles.ratioHeading}>
            <strong>{Math.round(data.warningPercentage)}%</strong>
            <span>Warnings</span>
          </div>
          <div
            className={styles.ratioTrack}
            aria-label="Warning and ticket ratio"
          >
            <span
              style={{
                width: `${Math.max(0, Math.min(100, data.warningPercentage))}%`,
              }}
            />
            <span
              style={{
                width: `${Math.max(0, Math.min(100, data.ticketPercentage))}%`,
              }}
            />
          </div>
          <div className={styles.ratioLabels}>
            <span>{data.warningCount.toLocaleString()} Warnings</span>
            <span>{data.ticketCount.toLocaleString()} Tickets</span>
          </div>
          <div className={styles.metricFooter}>
            <p className={styles.ratioTotal}>
              {data.totalInspectionCount.toLocaleString()} total inspections
            </p>
            <span className={styles.metricHint}>
              Warnings and tickets recorded
            </span>
          </div>
        </div>
      )}
    </AnalyticsPanel>
  );
}
