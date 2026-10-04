import type { ViolationResolutionRate } from "@/api/types/admin-analytics.types";
import AnalyticsPanel from "./AnalyticsPanel";
import styles from "./AnalyticsSummaryCards.module.css";

interface ResolutionRateCardProps {
  data?: ViolationResolutionRate;
  isLoading: boolean;
  isError: boolean;
  errorMessage: string;
  onRetry: () => void;
}

export default function ResolutionRateCard({
  data,
  isLoading,
  isError,
  errorMessage,
  onRetry,
}: ResolutionRateCardProps) {
  return (
    <AnalyticsPanel
      title="Resolution Rate"
      skeletonVariant="summary"
      isLoading={isLoading}
      isError={isError}
      errorMessage={errorMessage}
      onRetry={onRetry}
      className={styles.smallPanel}
    >
      {data && (
        <div className={styles.resolutionContent}>
          <strong>{Math.round(data.resolutionRate)}%</strong>
          <span>Resolved within 7 days</span>
          <div className={styles.resolutionStats}>
            <div>
              <strong>{data.resolvedWithinSevenDays.toLocaleString()}</strong>
              <span>Resolved</span>
            </div>
            <div>
              <strong>
                {Math.max(
                  0,
                  data.ticketCount - data.resolvedWithinSevenDays,
                ).toLocaleString()}
              </strong>
              <span>Remaining</span>
            </div>
            <div>
              <strong>{data.ticketCount.toLocaleString()}</strong>
              <span>Total tickets</span>
            </div>
          </div>
          <p>
            {data.resolvedWithinSevenDays.toLocaleString()} of{" "}
            {data.ticketCount.toLocaleString()} tickets
          </p>
        </div>
      )}
    </AnalyticsPanel>
  );
}
