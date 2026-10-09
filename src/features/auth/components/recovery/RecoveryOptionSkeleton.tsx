import SkeletonBlock from "@/components/ui/Skeleton/SkeletonBlock";
import styles from "./RecoveryOptionSkeleton.module.css";

export default function RecoveryOptionSkeleton() {
  return (
    <div className={styles.option} aria-hidden="true">
      <SkeletonBlock
        width="var(--recovery-control-height)"
        height="var(--recovery-control-height)"
        radius="var(--radius-sm)"
      />
      <div className={styles.text}>
        <SkeletonBlock width="70%" height="0.875rem" />
        <SkeletonBlock width="90%" height="0.75rem" />
      </div>
    </div>
  );
}
