import SkeletonBlock from "@/components/ui/Skeleton/SkeletonBlock";
import styles from "./EnforcerReportSkeleton.module.css";

const ROWS = 5;

export default function EnforcerReportSkeleton() {
  return (
    <div className={styles.skeleton}>
      <p className={styles.status} role="status">
        Loading report…
      </p>
      {Array.from({ length: ROWS }).map((_, index) => (
        <div key={index} className={styles.row}>
          <SkeletonBlock width="40%" height="14px" />
          <SkeletonBlock width="100%" height="14px" />
        </div>
      ))}
    </div>
  );
}
