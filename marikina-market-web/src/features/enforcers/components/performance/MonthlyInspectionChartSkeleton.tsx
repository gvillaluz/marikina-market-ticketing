import { FC } from "react";
import SkeletonBlock from "@/components/ui/Skeleton/SkeletonBlock";
import styles from "./MonthlyInspectionChartSkeleton.module.css";

const BAR_HEIGHTS = [45, 65, 50, 80, 90, 60, 40, 75, 55, 85, 70, 48];

const MonthlyInspectionsChartSkeleton: FC = () => {
  return (
    <div className={styles.card}>
      <SkeletonBlock width="150px" height="11px" />

      <div className={styles.bars}>
        {BAR_HEIGHTS.map((height, i) => (
          <div key={i} className={styles.barColumn}>
            <SkeletonBlock width="18px" height="9px" />
            <div className={styles.barTrack}>
              <SkeletonBlock
                width="100%"
                height={`${height}%`}
                radius="4px 4px 0 0"
              />
            </div>
            <SkeletonBlock width="20px" height="9px" />
          </div>
        ))}
      </div>
    </div>
  );
};

export default MonthlyInspectionsChartSkeleton;
