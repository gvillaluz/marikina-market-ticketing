import SkeletonBlock from "@/components/ui/Skeleton/SkeletonBlock";
import styles from "./PenaltyTiersSkeleton.module.css";

export default function PenaltyTiersSkeleton() {
  return (
    <div
      className={styles.skeleton}
      role="status"
      aria-label="Loading penalty tiers"
    >
      <span className={styles.caption}>Loading penalty tiers…</span>
      {[0, 1, 2].map((row) => (
        <div className={styles.row} key={row}>
          <SkeletonBlock
            width="var(--ordinance-badge-size)"
            height="var(--ordinance-badge-size)"
            radius="var(--market-radius-pill)"
          />
          <div className={styles.label}>
            <SkeletonBlock
              width="70%"
              height="var(--market-font-size-caption)"
            />
            <SkeletonBlock width="50%" height="var(--market-font-size-micro)" />
          </div>
          <SkeletonBlock
            width="100%"
            height="var(--ordinance-control-height)"
          />
          <SkeletonBlock
            width="100%"
            height="var(--ordinance-control-height)"
          />
        </div>
      ))}
    </div>
  );
}
