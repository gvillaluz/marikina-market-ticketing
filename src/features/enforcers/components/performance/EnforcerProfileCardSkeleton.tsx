import { FC } from "react";
import SkeletonBlock from "@/components/ui/Skeleton/SkeletonBlock";
import styles from "./EnforcerProfileCardSkeleton.module.css";

const EnforcerProfileCardSkeleton: FC = () => {
  return (
    <div className={styles.card}>
      <div className={styles.header}>
        <SkeletonBlock width="40px" height="40px" radius="50%" />
        <div className={styles.headerTitle}>
          <SkeletonBlock width="140px" height="16px" />
          <SkeletonBlock width="90px" height="12px" />
        </div>
      </div>

      <div className={styles.meta}>
        {Array.from({ length: 3 }).map((_, i) => (
          <div key={i} className={styles.metaItem}>
            <SkeletonBlock width="14px" height="14px" radius="4px" />
            <SkeletonBlock width="170px" height="12px" />
          </div>
        ))}
      </div>

      <div className={styles.tags}>
        <SkeletonBlock width="100%" height="36px" radius="6px" />
        <SkeletonBlock width="100%" height="36px" radius="6px" />
      </div>
    </div>
  );
};

export default EnforcerProfileCardSkeleton;
