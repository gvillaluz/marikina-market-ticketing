import Card from "@/components/ui/Card";
import SkeletonBlock from "@/components/ui/Skeleton/SkeletonBlock";
import styles from "./AdminVendorPerformanceSkeleton.module.css";

interface AdminVendorPerformanceSkeletonProps {
  variant: "profile" | "score";
}

export default function AdminVendorPerformanceSkeleton({
  variant,
}: AdminVendorPerformanceSkeletonProps) {
  if (variant === "profile") {
    return (
      <Card className={`${styles.profileCard} motion-enter`} aria-label="Loading vendor profile">
        <div className={styles.profileHeader}>
          <SkeletonBlock width="48px" height="48px" radius="50%" />
          <div className={styles.profileName}>
            <SkeletonBlock width="150px" height="14px" />
            <SkeletonBlock width="90px" height="10px" />
          </div>
        </div>
        <div className={styles.profileDetails}>
          <SkeletonBlock width="75%" height="10px" />
          <SkeletonBlock width="88%" height="10px" />
          <SkeletonBlock width="62%" height="10px" />
        </div>
        <SkeletonBlock width="100%" height="34px" radius="5px" />
      </Card>
    );
  }

  return (
    <Card className={`${styles.scoreCard} motion-enter`} aria-label="Loading compliance score">
      <SkeletonBlock width="110px" height="11px" />
      <div className={styles.scoreContent}>
        <SkeletonBlock width="124px" height="124px" radius="50%" />
        <div className={styles.scoreMetrics}>
          {Array.from({ length: 4 }).map((_, index) => (
            <div key={index}>
              <SkeletonBlock width="110px" height="9px" />
              <SkeletonBlock width="48px" height="9px" />
            </div>
          ))}
        </div>
      </div>
      <SkeletonBlock width="100%" height="24px" />
    </Card>
  );
}
