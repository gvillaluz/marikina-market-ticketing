import { LucideIcon, TriangleAlert } from "lucide-react";
import Button from "@/components/ui/Button/Button";
import styles from "./UnavailableStatCard.module.css";

interface UnavailableStatCardProps {
  icon: LucideIcon;
  iconColor: string;
  iconBg: string;
  label: string;
  message: string;
  busy: boolean;
  onRetry: () => void;
}

export default function UnavailableStatCard({
  icon: Icon,
  iconColor,
  iconBg,
  label,
  message,
  busy,
  onRetry,
}: UnavailableStatCardProps) {
  return (
    <div className={styles.card}>
      <div className={styles.header}>
        <div
          className={styles.iconWrap}
          style={{ background: iconBg, color: iconColor }}
        >
          <Icon size={20} strokeWidth={2} />
        </div>
        <div>
          <span className={styles.value}>Unavailable</span>
          <span className={styles.label}>{label}</span>
        </div>
      </div>
      <div className={styles.footer} role="alert">
        <p className={styles.message}>
          <TriangleAlert size={14} strokeWidth={2.25} aria-hidden="true" />
          {message}
        </p>
        <Button
          type="button"
          variant="outline"
          size="sm"
          className={styles.retry}
          disabled={busy}
          onClick={onRetry}
        >
          {busy ? "Retrying…" : "Try again"}
        </Button>
      </div>
    </div>
  );
}
