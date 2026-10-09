import SkeletonBlock from "@/components/ui/Skeleton/SkeletonBlock";
import ReviewSkeletonSection from "./ReviewSkeletonSection";
import styles from "./ReviewSkeleton.module.css";

export default function ReviewSkeleton() {
  return (
    <div
      className={styles.page}
      role="status"
      aria-label="Loading registration review"
    >
      <SkeletonBlock width="180px" height="10px" />
      <div className={styles.skeletonHeader}>
        <SkeletonBlock width="240px" height="20px" />
        <SkeletonBlock width="420px" height="10px" />
      </div>
      <div className={styles.columns}>
        <main className={styles.main}>
          <div className={styles.applicant}>
            <SkeletonBlock width="28px" height="28px" radius="50%" />
            <div className={styles.skeletonApplicantText}>
              <SkeletonBlock width="150px" height="11px" />
              <SkeletonBlock width="220px" height="8px" />
            </div>
            <SkeletonBlock width="120px" height="18px" />
          </div>
          <ReviewSkeletonSection columns={6} />
          <ReviewSkeletonSection columns={3} />
          <ReviewSkeletonSection columns={3} />
          <div className={styles.section}>
            <SkeletonBlock width="150px" height="11px" />
            <SkeletonBlock width="230px" height="8px" />
            <div className={styles.skeletonDocuments}>
              <SkeletonBlock width="100%" height="105px" />
              <SkeletonBlock width="100%" height="105px" />
            </div>
          </div>
        </main>
        <div className={styles.checklist}>
          <SkeletonBlock width="130px" height="11px" />
          <SkeletonBlock width="180px" height="8px" />
          {Array.from({ length: 6 }).map((_, index) => (
            <div className={styles.skeletonChecklistItem} key={index}>
              <SkeletonBlock width="14px" height="14px" radius="50%" />
              <div>
                <SkeletonBlock width="150px" height="8px" />
                <SkeletonBlock width="110px" height="7px" />
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
