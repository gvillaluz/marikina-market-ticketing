import type { ReactNode } from "react";
import styles from "./RegistryTable.module.css";

export interface RegistryColumn {
  label: string;
  className?: string;
  hidden?: boolean;
}

interface RegistryTableProps {
  columns: readonly RegistryColumn[];
  children: ReactNode;
  ariaLabel: string;
  labelledBy?: string;
  busy?: boolean;
  className?: string;
}

export default function RegistryTable({
  columns,
  children,
  ariaLabel,
  labelledBy,
  busy = false,
  className = "",
}: RegistryTableProps) {
  return (
    <div
      className={`${styles.region} ${className}`}
      role="region"
      aria-label={ariaLabel}
      aria-busy={busy}
      tabIndex={0}
    >
      <table
        className={styles.table}
        aria-labelledby={labelledBy}
        aria-label={labelledBy ? undefined : ariaLabel}
      >
        <thead>
          <tr>
            {columns.map((column) => (
              <th key={column.label} scope="col" className={column.className}>
                {column.hidden ? (
                  <span className={styles.srOnly}>{column.label}</span>
                ) : (
                  column.label
                )}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>{children}</tbody>
      </table>
    </div>
  );
}
