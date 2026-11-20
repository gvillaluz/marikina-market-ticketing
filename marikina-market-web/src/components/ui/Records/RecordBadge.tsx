import styles from "./RecordBadge.module.css";

const TONES: Record<string, string> = {
  pending: "warning",
  contested: "warning",
  inprogress: "warning",
  warning: "warning",
  moderate: "warning",
  paid: "success",
  cleared: "success",
  active: "success",
  minor: "success",
  overdue: "danger",
  ticket: "danger",
  high: "danger",
  rejected: "danger",
  waived: "violet",
  inactive: "neutral",
};

export function RecordBadge({ value, label }: { value: string; label?: string }) {
  return (
    <span
      className={`${styles.badge} ${styles[TONES[value.toLowerCase()] ?? "neutral"]}`}
    >
      {label || value || "—"}
    </span>
  );
}
