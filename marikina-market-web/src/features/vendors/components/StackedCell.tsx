import type { ReactNode } from "react";
import styles from "./StackedCell.module.css";

interface StackedCellProps {
  primary: ReactNode;
  secondary: ReactNode;
}

export default function StackedCell({ primary, secondary }: StackedCellProps) {
  return (
    <div className={styles.cell}>
      <span className={styles.primary}>{primary}</span>
      <span className={styles.secondary}>{secondary}</span>
    </div>
  );
}
