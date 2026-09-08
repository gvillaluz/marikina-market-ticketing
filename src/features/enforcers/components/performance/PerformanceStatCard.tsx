import { FC } from "react";
import styles from "./PerformanceStatCard.module.css";

interface PerformanceStatCardProps {
  label: string;
  value: string | number;
  subLabel?: string;
  secondaryLabel?: string;
  progress?: number;
}

const PerformanceStatCard: FC<PerformanceStatCardProps> = ({
  label,
  value,
  subLabel,
  secondaryLabel,
  progress,
}) => {
  return (
    <div className={styles.card}>
      <p className={styles.label}>{label}</p>
      <p className={styles.value}>{value}</p>
      {subLabel && <p className={styles.subLabel}>{subLabel}</p>}

      {typeof progress === "number" && (
        <>
          <div className={styles.progressTrack}>
            <div
              className={styles.progressBar}
              style={{ width: `${Math.min(Math.max(progress, 0), 100)}%` }}
            />
          </div>
          {secondaryLabel && (
            <p className={styles.secondaryLabel}>{secondaryLabel}</p>
          )}
        </>
      )}
    </div>
  );
};

export default PerformanceStatCard;
