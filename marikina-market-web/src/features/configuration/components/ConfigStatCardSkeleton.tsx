import SkeletonBlock from "@/components/ui/Skeleton/SkeletonBlock";
import styles from "./ConfigStatCardSkeleton.module.css";

export default function ConfigStatCardSkeleton() {
  return (
    <div className={styles.card} aria-hidden="true" data-config-stat-skeleton>
      <div className={styles.header}>
        <SkeletonBlock width="40px" height="40px" radius="var(--radius-sm)" />
        <div className={styles.summary}>
          <SkeletonBlock width="3.5rem" height="1.2rem" />
          <SkeletonBlock width="6rem" height="0.65rem" />
        </div>
      </div>
      <SkeletonBlock width="60%" height="0.75rem" />
    </div>
  );
}
