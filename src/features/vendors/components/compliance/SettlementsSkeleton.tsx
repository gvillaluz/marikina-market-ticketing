import SkeletonBlock from "@/components/ui/Skeleton/SkeletonBlock";
import styles from "../AdminVendorCompliancePanel.module.css";

export default function SettlementsSkeleton() {
  return (
    <div
      className={styles.skeletonSettlements}
      aria-label="Loading settlements"
    >
      {[0, 1, 2].map((item) => (
        <div className={styles.skeletonSettlement} key={item}>
          <div className={styles.skeletonSettlementTop}>
            <SkeletonBlock width="56%" height="12px" />
            <SkeletonBlock width="48px" height="9px" />
          </div>
          <SkeletonBlock width="68%" height="10px" />
          <SkeletonBlock width="43%" height="10px" />
        </div>
      ))}
    </div>
  );
}
