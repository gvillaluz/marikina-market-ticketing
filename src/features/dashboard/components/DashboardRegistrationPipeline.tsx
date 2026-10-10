import { ArrowUpRight, FileClock } from "lucide-react";
import { Link } from "react-router-dom";
import type { VendorRegistrationStatusCounts } from "@/api/types/admin-vendor.types";
import Button from "@/components/ui/Button/Button";
import SkeletonBlock from "@/components/ui/Skeleton/SkeletonBlock";
import { ROUTES } from "@/routes/routePaths";
import styles from "./DashboardRegistrationPipeline.module.css";

interface DashboardRegistrationPipelineProps {
  counts?: VendorRegistrationStatusCounts;
  isLoading: boolean;
  error: string | null;
  onRetry: () => void;
}

const STATUS_ITEMS = [
  { key: "pendingReview", label: "Pending review", tone: "pending" },
  {
    key: "needsInformation",
    label: "Needs information",
    tone: "information",
  },
  { key: "approved", label: "Approved", tone: "approved" },
  { key: "rejected", label: "Rejected", tone: "rejected" },
] as const;

export default function DashboardRegistrationPipeline({
  counts,
  isLoading,
  error,
  onRetry,
}: DashboardRegistrationPipelineProps) {
  return (
    <article className={styles.panel} aria-busy={isLoading}>
      <div className={styles.heading}>
        <span className={styles.icon} aria-hidden="true">
          <FileClock size={17} />
        </span>
        <h2>Registration pipeline</h2>
      </div>

      {isLoading ? (
        <div className={styles.loading} aria-label="Loading registration statuses">
          {STATUS_ITEMS.map((item) => (
            <div className={styles.loadingItem} key={item.key}>
              <SkeletonBlock width="65%" height="0.8rem" />
              <SkeletonBlock width="2rem" height="1rem" />
            </div>
          ))}
        </div>
      ) : error ? (
        <div className={styles.error} role="alert">
          <p>{error}</p>
          <Button type="button" variant="outline" size="sm" onClick={onRetry}>
            Try again
          </Button>
        </div>
      ) : (
        <>
          <div className={styles.statusGrid}>
            {STATUS_ITEMS.map(({ key, label, tone }) => (
              <div className={styles.statusItem} key={key}>
                <span>{label}</span>
                <strong className={styles[tone]}>
                  {counts?.[key].toLocaleString() ?? "—"}
                </strong>
              </div>
            ))}
          </div>
          <Link className={styles.link} to={ROUTES.adminVendorRegistrations}>
            View registrations
            <ArrowUpRight size={15} aria-hidden="true" />
          </Link>
        </>
      )}
    </article>
  );
}
