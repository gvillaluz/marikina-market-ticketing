import type { ReactNode } from "react";
import styles from "./StaffAccountSection.module.css";

interface StaffAccountSectionProps {
  number: number;
  title: string;
  subtitle: string;
  children: ReactNode;
}

export default function StaffAccountSection({
  number,
  title,
  subtitle,
  children,
}: StaffAccountSectionProps) {
  return (
    <section className={styles.section}>
      <header className={styles.header}>
        <span className={styles.number} aria-hidden="true">
          {number}
        </span>
        <div>
          <h3>{title}</h3>
          <p>{subtitle}</p>
        </div>
      </header>
      {children}
    </section>
  );
}
