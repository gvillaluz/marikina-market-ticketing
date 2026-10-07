import type { ReactNode } from "react";
import styles from "../AdminVendorRegistrationReviewPage.module.css";

interface ReviewSectionProps {
  title: string;
  subtitle: string;
  children: ReactNode;
}

export default function ReviewSection({
  title,
  subtitle,
  children,
}: ReviewSectionProps) {
  return (
    <section className={styles.section}>
      <h2>{title}</h2>
      <p className={styles.sectionSubtitle}>{subtitle}</p>
      {children}
    </section>
  );
}
