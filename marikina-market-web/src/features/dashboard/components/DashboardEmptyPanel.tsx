import { Children, type ReactNode } from "react";
import type { LucideIcon } from "lucide-react";
import Button from "@/components/ui/Button/Button";
import SkeletonBlock from "@/components/ui/Skeleton/SkeletonBlock";
import styles from "./DashboardEmptyPanel.module.css";

interface DashboardEmptyPanelProps {
  title: string;
  description: string;
  icon: LucideIcon;
  iconLabel: string;
  children?: ReactNode;
  isLoading?: boolean;
  error?: string | null;
  onRetry?: () => void;
  tone?: "primary" | "warning" | "success" | "info";
}

export default function DashboardEmptyPanel({
  title,
  description,
  icon: Icon,
  iconLabel,
  children,
  isLoading = false,
  error = null,
  onRetry,
  tone = "primary",
}: DashboardEmptyPanelProps) {
  return (
    <article className={styles.panel} aria-busy={isLoading}>
      <div className={styles.heading}>
        <span className={`${styles.icon} ${styles[tone]}`} aria-hidden="true">
          <Icon size={18} />
        </span>
        <h2>{title}</h2>
      </div>
      {isLoading ? (
        <div className={styles.loading} aria-label={`Loading ${title}`}>
          {[0, 1, 2].map((row) => (
            <div className={styles.loadingRow} key={row}>
              <SkeletonBlock width="2rem" height="2rem" radius="50%" />
              <span className={styles.loadingText}>
                <SkeletonBlock width="55%" />
                <SkeletonBlock width="80%" height="11px" />
              </span>
            </div>
          ))}
        </div>
      ) : error ? (
        <div className={styles.empty} role="alert">
          <p>{error}</p>
          {onRetry && (
            <Button type="button" variant="outline" size="sm" onClick={onRetry}>
              Try again
            </Button>
          )}
        </div>
      ) : Children.count(children) > 0 ? (
        <div className={styles.content}>{children}</div>
      ) : (
        <div className={styles.empty}>
          <span className={styles.emptyIcon} aria-hidden="true">
            <Icon size={22} />
          </span>
          <p>{iconLabel}</p>
          <span>{description}</span>
        </div>
      )}
    </article>
  );
}
