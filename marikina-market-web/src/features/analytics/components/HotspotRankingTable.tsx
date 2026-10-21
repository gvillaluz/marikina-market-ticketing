import { ArrowDown, ArrowUp, Minus } from "lucide-react";
import type { HotspotRanking } from "@/api/types/admin-analytics.types";
import AnalyticsPanel from "./AnalyticsPanel";
import styles from "./HotspotRankingTable.module.css";

interface HotspotRankingTableProps {
  data: HotspotRanking[];
  isLoading: boolean;
  isError: boolean;
  errorMessage: string;
  onRetry: () => void;
}

function trendDirection(trend: string): "up" | "down" | "stable" {
  switch (trend.toLowerCase()) {
    case "rising":
      return "up";
    case "falling":
      return "down";
    case "stable":
    default:
      return "stable";
  }
}

export default function HotspotRankingTable({
  data,
  isLoading,
  isError,
  errorMessage,
  onRetry,
}: HotspotRankingTableProps) {
  return (
    <AnalyticsPanel
      title="Hotspot Ranking"
      subtitle="Market sections with the highest violation activity."
      skeletonVariant="table"
      isLoading={isLoading}
      isError={isError}
      errorMessage={errorMessage}
      onRetry={onRetry}
      className={styles.panel}
    >
      <div className={styles.tableWrap}>
        <table className={styles.table}>
          <thead>
            <tr>
              <th scope="col">Rank</th>
              <th scope="col">Market Section</th>
              <th scope="col">Count</th>
              <th scope="col">Trend</th>
            </tr>
          </thead>
          <tbody>
            {data.map((hotspot) => {
              const direction = trendDirection(hotspot.trend);
              const TrendIcon = direction === "up" ? ArrowUp : direction === "down" ? ArrowDown : Minus;
              return (
                <tr key={hotspot.marketSectionId}>
                  <td>#{hotspot.rank}</td>
                  <td>{hotspot.marketSectionName}</td>
                  <td>{hotspot.totalInspectionCount}</td>
                  <td>
                    <span
                      className={`${styles.trend} ${styles[direction]}`}
                      title={hotspot.trend}
                      role="img"
                      aria-label={`${hotspot.trend} trend`}
                    >
                      <TrendIcon size={12} aria-hidden="true" />
                    </span>
                  </td>
                </tr>
              );
            })}
            {data.length === 0 && (
              <tr><td className={styles.empty} colSpan={4}>No hotspot rankings available.</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </AnalyticsPanel>
  );
}
