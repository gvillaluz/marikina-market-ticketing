import { FC } from "react";
import SkeletonBlock from "@/components/ui/Skeleton/SkeletonBlock";
import styles from "./PerformanceStatCardSkeleton.module.css";

interface PerformanceStatCardSkeletonProps {
  withProgress?: boolean;
}

const PerformanceStatCardSkeleton: FC<PerformanceStatCardSkeletonProps> = ({
  withProgress,
}) => {
  return (
    <div className={styles.card}>
      {!withProgress && (
        <SkeletonBlock width="30px" height="30px" radius="8px" />
      )}
      <SkeletonBlock width={withProgress ? "40%" : "60%"} height="12px" />
      <SkeletonBlock width={withProgress ? "35%" : "50%"} height="24px" />

      {withProgress && (
        <>
          <SkeletonBlock width="100%" height="8px" radius="4px" />
          <SkeletonBlock width="45%" height="10px" />
        </>
      )}
    </div>
  );
};

export default PerformanceStatCardSkeleton;
