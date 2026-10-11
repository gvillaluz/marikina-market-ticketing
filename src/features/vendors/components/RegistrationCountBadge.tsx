import { CircleAlert } from "lucide-react";
import { Badge } from "@/components/ui/Badge/Badge";
import { useRegistrationStatusCounts } from "../hooks/useRegistrationStatusCounts";
import styles from "./RegistrationCountBadge.module.css";

interface RegistrationCountBadgeProps {
  compact: boolean;
}

export function RegistrationCountBadge({
  compact,
}: RegistrationCountBadgeProps) {
  const { counts, isLoading, error, enabled } =
    useRegistrationStatusCounts(true);
  const count = counts?.pendingReview;
  if (!enabled || (count === 0 && !error)) return null;
  if (count === undefined && !isLoading && !error) return null;

  const hasCount = count !== undefined && count > 0;
  const title = error
    ? `${error} ${hasCount ? `Last known count: ${count} pending registration requests. ` : ""}The count will refresh automatically.`
    : hasCount
      ? `${count} pending registration ${count === 1 ? "request" : "requests"}`
      : "Loading pending registration requests";

  return (
    <span
      className={`${styles.badge} ${compact ? styles.compact : ""}`}
      title={title}
      aria-label={title}
      role="status"
    >
      <Badge tone="neutral" className={styles.count}>
        <span aria-hidden="true">
          {hasCount ? (
            count > 99 ? (
              "99+"
            ) : (
              count
            )
          ) : error ? (
            <CircleAlert className={styles.statusIcon} />
          ) : (
            "…"
          )}
        </span>
      </Badge>
    </span>
  );
}
