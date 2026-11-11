import SkeletonBlock from "@/components/ui/Skeleton/SkeletonBlock";
import styles from "./PersonTicketHistorySkeleton.module.css";

export default function PersonTicketHistorySkeleton() {
  return (
    <div className={styles.list} role="status" aria-label="Loading citation history">
      {[0, 1].map(row => <div key={row} className={styles.card}>
        <SkeletonBlock width="40%" height="20px" />
        <SkeletonBlock width="65%" />
        <SkeletonBlock height="48px" />
      </div>)}
    </div>
  );
}
