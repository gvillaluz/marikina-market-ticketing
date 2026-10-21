import SkeletonBlock from "@/components/ui/Skeleton/SkeletonBlock";
import styles from "./ReviewSkeletonSection.module.css";

export default function ReviewSkeletonSection({
  columns,
}: {
  columns: number;
}) {
  return (
    <div className={styles.section}>
      <SkeletonBlock width="160px" height="11px" />
      <SkeletonBlock width="260px" height="8px" />
      <div
        className={`${styles.skeletonFields} ${
          columns === 6 ? styles.sixColumns : styles.threeColumns
        }`}
      >
        {Array.from({ length: columns }).map((_, index) => (
          <div key={index}>
            <SkeletonBlock width="65px" height="7px" />
            <SkeletonBlock width="100%" height="10px" />
          </div>
        ))}
      </div>
    </div>
  );
}
