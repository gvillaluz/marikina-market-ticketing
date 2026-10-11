import SkeletonBlock from "@/components/ui/Skeleton/SkeletonBlock";
import styles from "./AuditDetailSkeleton.module.css";

export default function AuditDetailSkeleton() {
  return (
    <div className={styles.content} role="status" aria-busy="true">
      <p className={styles.label}>Loading audit details…</p>
      <SkeletonBlock width="25%" height="var(--form-font-body)" />
      <div className={styles.fields} aria-hidden="true">
        {Array.from({ length: 7 }, (_, index) => (
          <div className={styles.field} key={index}>
            <SkeletonBlock width="40%" height="var(--form-font-caption)" />
            <SkeletonBlock width="75%" height="var(--form-font-body)" />
          </div>
        ))}
      </div>
      <div className={styles.details} aria-hidden="true">
        <SkeletonBlock width="25%" height="var(--form-font-body)" />
        <SkeletonBlock width="100%" height="var(--form-font-body)" />
        <SkeletonBlock width="80%" height="var(--form-font-body)" />
      </div>
    </div>
  );
}
