import SkeletonBlock from "@/components/ui/Skeleton/SkeletonBlock";
import styles from "./AuditStatCardSkeleton.module.css";

export default function AuditStatCardSkeleton() {
  return (
    <div className={styles.card} aria-hidden="true" data-audit-skeleton>
      <div className={styles.header}>
        <SkeletonBlock
          width="var(--account-icon-size)"
          height="var(--account-icon-size)"
          radius="var(--radius-sm)"
        />
        <div className={styles.summary}>
          <SkeletonBlock width="3.25rem" height="var(--font-size-h2)" />
          <SkeletonBlock
            width="8rem"
            height="var(--market-font-size-caption)"
          />
        </div>
      </div>
      <div className={styles.note}>
        <SkeletonBlock width="78%" height="var(--market-font-size-caption)" />
      </div>
    </div>
  );
}
