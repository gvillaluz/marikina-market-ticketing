import type { ReactNode } from "react";
import { AlertTriangle, RefreshCw } from "lucide-react";
import Card from "@/components/ui/Card";
import SkeletonBlock from "@/components/ui/Skeleton/SkeletonBlock";
import styles from "./AnalyticsPanel.module.css";

type SkeletonVariant = "chart" | "heatmap" | "distribution" | "summary" | "table";

interface AnalyticsPanelProps {
  title: string;
  subtitle?: string;
  skeletonVariant?: SkeletonVariant;
  isLoading: boolean;
  isError: boolean;
  errorMessage: string;
  onRetry: () => void;
  children: ReactNode;
  className?: string;
}

export default function AnalyticsPanel({
  title,
  subtitle,
  skeletonVariant = "chart",
  isLoading,
  isError,
  errorMessage,
  onRetry,
  children,
  className = "",
}: AnalyticsPanelProps) {
  return (
    <Card className={`${styles.panel} ${className}`}>
      <header className={styles.header}>
        <div>
          <h2>{title}</h2>
          {subtitle && <p>{subtitle}</p>}
        </div>
      </header>
      {isLoading ? (
        <div className={styles.skeleton} role="status" aria-label={`Loading ${title}`}>
          {skeletonVariant === "chart" && (
            <>
              <SkeletonBlock width="100%" height="145px" radius="5px" />
              <div className={styles.skeletonLegend}>
                <SkeletonBlock width="75px" height="9px" />
                <SkeletonBlock width="75px" height="9px" />
                <SkeletonBlock width="75px" height="9px" />
              </div>
            </>
          )}
          {skeletonVariant === "heatmap" && (
            <>
              {Array.from({ length: 6 }).map((_, row) => (
                <div className={styles.skeletonHeatRow} key={row}>
                  <SkeletonBlock width="40px" height="14px" />
                  {Array.from({ length: 6 }).map((__, cell) => (
                    <SkeletonBlock key={cell} width="100%" height="20px" />
                  ))}
                </div>
              ))}
            </>
          )}
          {skeletonVariant === "distribution" && (
            <div className={styles.skeletonDistribution}>
              <SkeletonBlock width="112px" height="112px" radius="50%" />
              <div>
                {Array.from({ length: 5 }).map((_, row) => (
                  <SkeletonBlock key={row} width="100%" height="13px" />
                ))}
              </div>
            </div>
          )}
          {skeletonVariant === "summary" && (
            <>
              <SkeletonBlock width="88px" height="27px" />
              <SkeletonBlock width="100%" height="9px" />
              <SkeletonBlock width="76%" height="11px" />
            </>
          )}
          {skeletonVariant === "table" && (
            <>
              <SkeletonBlock width="100%" height="24px" />
              {Array.from({ length: 5 }).map((_, row) => (
                <SkeletonBlock key={row} width="100%" height="25px" />
              ))}
            </>
          )}
        </div>
      ) : isError ? (
        <div className={styles.state} role="alert">
          <AlertTriangle size={19} aria-hidden="true" />
          <div>
            <strong>Analytics unavailable</strong>
            <span>{errorMessage}</span>
          </div>
          <button type="button" onClick={onRetry} aria-label={`Retry loading ${title}`}>
            <RefreshCw size={14} aria-hidden="true" /> Try again
          </button>
        </div>
      ) : children}
    </Card>
  );
}
