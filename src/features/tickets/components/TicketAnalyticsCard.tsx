import styles from './TicketAnalyticsCard.module.css';
import Card from "@/components/ui/Card";
import SkeletonBlock from "@/components/ui/Skeleton/SkeletonBlock";
import { FC } from "react";

const TicketAnalyticsCard: FC<{
  label: string;
  value: string;
  change?: number;
  progress?: number;
  isLoading?: boolean;
}> = ({ label, value, change, progress, isLoading = false }) => {
  return (
    <Card className={styles.stat}>
      <span className={styles.statLabel}>{label}</span>
      {isLoading ? <>
        <SkeletonBlock width="4rem" height="1.75rem" />
        <SkeletonBlock width="7rem" height="0.75rem" />
        {progress !== undefined && <SkeletonBlock width="100%" height="0.3rem" />}
      </> : <>
      <strong className={styles.statValue}>{value}</strong>

      {change !== undefined && (
        <span className={styles.change}>
          {change >= 0 ? "+" : ""}
          {change}% vs last month
        </span>
      )}

      {progress !== undefined && (
        <>
          <span className={styles.change}>{progress}% resolution rate</span>
          <div className={styles.progress}>
            <span style={{ width: `${progress}%` }} />
          </div>
        </>
      )}
      </>}
    </Card>
  );
};
export default TicketAnalyticsCard;
