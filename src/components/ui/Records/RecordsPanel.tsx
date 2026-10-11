import type { ReactNode } from "react";
import styles from "./RecordsPanel.module.css";

interface RecordsPanelProps {
  title: string;
  description: string;
  count?: number;
  countLabel: string;
  updating?: boolean;
  children: ReactNode;
}

export function RecordsPanel({
  title,
  description,
  count,
  countLabel,
  updating,
  children,
}: RecordsPanelProps) {
  return (
    <section
      className={styles.panel}
      aria-label={title}
      aria-busy={updating || undefined}
    >
      <div className={styles.header}>
        <div className={styles.heading}>
          <h2>{title}</h2>
          <p>{description}</p>
        </div>
        <div className={styles.summary}>
          {updating && (
            <span className={styles.updating} role="status">
              Updating records…
            </span>
          )}
          {count !== undefined && (
            <span className={styles.count}>
              {count.toLocaleString()} {countLabel}
            </span>
          )}
        </div>
      </div>
      {children}
    </section>
  );
}
