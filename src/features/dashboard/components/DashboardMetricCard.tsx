import type { LucideIcon } from "lucide-react";
import SkeletonBlock from "@/components/ui/Skeleton/SkeletonBlock";
import styles from "./DashboardMetricCard.module.css";

type DashboardMetricTone = "primary" | "warning" | "success" | "info";

interface DashboardMetricCardProps {
  label: string;
  description: string;
  icon: LucideIcon;
  tone: DashboardMetricTone;
  value: number | null;
  isLoading: boolean;
}

export default function DashboardMetricCard({
  label,
  description,
  icon: Icon,
  tone,
  value,
  isLoading,
}: DashboardMetricCardProps) {
  return (
    <article className={styles.card} aria-busy={isLoading}>
      <div className={styles.topLine}>
        <span className={`${styles.icon} ${styles[tone]}`} aria-hidden="true">
          <Icon size={19} strokeWidth={2} />
        </span>
        <span className={styles.pending}>{isLoading ? "Loading" : "Live"}</span>
      </div>
      <p className={styles.label}>{label}</p>
      {isLoading ? (
        <SkeletonBlock width="5rem" height="2rem" />
      ) : (
        <p
          className={styles.value}
          aria-label={
            value === null ? `${label}: unavailable` : `${label}: ${value}`
          }
        >
          {value === null ? "—" : value.toLocaleString()}
        </p>
      )}
      <p className={styles.description}>{description}</p>
    </article>
  );
}
