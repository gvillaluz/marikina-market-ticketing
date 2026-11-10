import type { MarketSectionAggregation } from "@/api/types/admin-analytics.types";
import AnalyticsPanel from "./AnalyticsPanel";
import styles from "./MarketSectionAggregationChart.module.css";

interface MarketSectionAggregationChartProps {
  data: MarketSectionAggregation[];
  isLoading: boolean;
  isError: boolean;
  errorMessage: string;
  onRetry: () => void;
}

function countLabel(count: number, singular: string) {
  return `${count} ${count === 1 ? singular : `${singular}s`}`;
}

export default function MarketSectionAggregationChart({
  data,
  isLoading,
  isError,
  errorMessage,
  onRetry,
}: MarketSectionAggregationChartProps) {
  const rows = [...data].sort(
    (first, second) => second.totalInspectionCount - first.totalInspectionCount,
  );
  const maxValue = Math.max(1, ...rows.map((row) => row.totalInspectionCount));

  return (
    <AnalyticsPanel
      title="Market Section Aggregation"
      subtitle="Warnings and tickets in each market section. Bar length is warnings plus tickets."
      skeletonVariant="chart"
      isLoading={isLoading}
      isError={isError}
      errorMessage={errorMessage}
      onRetry={onRetry}
      className={styles.panel}
    >
      <div className={styles.chart}>
        {rows.map((row) => (
          <div className={styles.row} key={row.marketSectionId}>
            <span className={styles.name} title={row.marketSectionName}>
              {row.marketSectionName}
            </span>
            <div
              className={styles.track}
              role="img"
              aria-label={`${row.marketSectionName}: ${countLabel(row.warningCount, "warning")} and ${countLabel(row.ticketCount, "ticket")}`}
            >
              <span style={{ width: `${(row.totalInspectionCount / maxValue) * 100}%` }} />
            </div>
            <strong>
              {countLabel(row.warningCount, "warning")} · {countLabel(row.ticketCount, "ticket")}
            </strong>
          </div>
        ))}
        {rows.length === 0 && <p className={styles.empty}>No market section data available.</p>}
      </div>
    </AnalyticsPanel>
  );
}
