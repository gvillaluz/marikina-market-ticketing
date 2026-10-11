import styles from "./RecordBadge.module.css";

const TONES: Record<string, string> = {
  pending: "warning",
  contested: "warning",
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

export function RecordBadge({ value }: { value: string }) {
  return (
    <span
      className={`${styles.badge} ${styles[TONES[value.toLowerCase()] ?? "neutral"]}`}
    >
      {value || "—"}
    </span>
  );
}
