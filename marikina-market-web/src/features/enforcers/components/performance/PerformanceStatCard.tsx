import { FC } from "react";
import styles from "./PerformanceStatCard.module.css";
import { ClipboardCheck, UserRoundSearch } from "lucide-react";

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
      {progress == null ? (
        <>
          <div className={styles.icon}>
            {label.toLowerCase() == "total inspections" ? (
              <ClipboardCheck />
            ) : (
              <UserRoundSearch />
            )}
          </div>
          <span className={styles.value}>{value}</span>
          <span className={styles.label}>{label}</span>
        </>
      ) : (
        <>
          <span className={styles.label}>{label}</span>
          <span className={styles.value}>
            {value} <span className={styles.subLabel}>{subLabel}</span>
          </span>
        </>
      )}

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
