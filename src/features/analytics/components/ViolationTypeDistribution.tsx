import type { CSSProperties } from "react";
import type { ViolationCategoryDistribution } from "@/api/types/admin-analytics.types";
import AnalyticsPanel from "./AnalyticsPanel";
import styles from "./ViolationTypeDistribution.module.css";

interface ViolationTypeDistributionProps {
  data: ViolationCategoryDistribution[];
  isLoading: boolean;
  isError: boolean;
  errorMessage: string;
  onRetry: () => void;
}

const CATEGORY_COLORS = [
  "#ed6a22",
  "#16a4c7",
  "#7c3fc7",
  "#e9a51b",
  "#e34945",
  "#38875c",
  "#3b6fb6",
  "#9b6b45",
];

export default function ViolationTypeDistribution({
  data,
  isLoading,
  isError,
  errorMessage,
  onRetry,
}: ViolationTypeDistributionProps) {
  const total = data.reduce((sum, item) => sum + item.ticketCount, 0);
  let angle = 0;
  const gradient = data.length > 0
    ? data.map((item, index) => {
        const start = angle;
        const proportion = total > 0
          ? (Math.max(0, item.ticketCount) / total) * 100
          : Math.max(0, item.percentage);
        angle += proportion;
        return `${CATEGORY_COLORS[index % CATEGORY_COLORS.length]} ${start}% ${angle}%`;
      }).join(", ")
    : "#e8edf3 0% 100%";

  return (
    <AnalyticsPanel
      title="Violation Type Distribution"
      subtitle="Percentage share of violations by recorded category."
      skeletonVariant="distribution"
      isLoading={isLoading}
      isError={isError}
      errorMessage={errorMessage}
      onRetry={onRetry}
      className={styles.panel}
    >
      <div className={styles.content}>
        <div
          className={styles.donut}
          style={{ "--distribution-gradient": `conic-gradient(${gradient})` } as CSSProperties}
          role="img"
          aria-label={`Distribution of ${total} violations across ${data.length} categories`}
        >
          <div className={styles.donutCenter}>
            <strong>{total.toLocaleString()}</strong>
            <span>Tickets</span>
          </div>
        </div>
        <ul className={styles.categoryList}>
          {data.map((item, index) => (
            <li key={item.category}>
              <span className={styles.categoryName}>
                <i style={{ backgroundColor: CATEGORY_COLORS[index % CATEGORY_COLORS.length] }} />
                {item.category}
              </span>
              <strong>{item.ticketCount.toLocaleString()}</strong>
              <span>{Math.round(total > 0 ? (item.ticketCount / total) * 100 : item.percentage)}%</span>
            </li>
          ))}
          {data.length === 0 && <li className={styles.empty}>No category data available.</li>}
        </ul>
      </div>
    </AnalyticsPanel>
  );
}
