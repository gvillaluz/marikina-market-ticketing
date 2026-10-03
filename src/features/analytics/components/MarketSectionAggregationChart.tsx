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
      subtitle="Inspection counts across all market sections."
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
              aria-label={`${row.marketSectionName}: ${row.totalInspectionCount} inspections`}
            >
              <span style={{ width: `${(row.totalInspectionCount / maxValue) * 100}%` }} />
            </div>
            <strong>{row.totalInspectionCount}</strong>
          </div>
        ))}
        {rows.length === 0 && <p className={styles.empty}>No market section data available.</p>}
      </div>
    </AnalyticsPanel>
  );
}
