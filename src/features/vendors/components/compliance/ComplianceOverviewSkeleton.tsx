import Card from "@/components/ui/Card";
import SkeletonBlock from "@/components/ui/Skeleton/SkeletonBlock";
import styles from "../AdminVendorCompliancePanel.module.css";

export default function ComplianceOverviewSkeleton() {
  return (
    <>
      <div className={styles.summaryStats} aria-label="Loading market activity">
        {[0, 1].map((item) => (
          <Card
            className={`${styles.summaryStat} ${styles.skeletonStat}`}
            key={item}
          >
            <SkeletonBlock width="54%" height="19px" />
            <SkeletonBlock width="76%" height="10px" />
          </Card>
        ))}
      </div>
      <section className={styles.panelSection}>
        <h3>New Activities</h3>
        <div className={styles.activityList}>
          {[0, 1, 2].map((item) => (
            <div className={styles.skeletonActivity} key={item}>
              <SkeletonBlock width="32px" height="32px" radius="50%" />
              <div>
                <SkeletonBlock width="180px" height="11px" />
                <SkeletonBlock width="130px" height="9px" />
              </div>
              <SkeletonBlock width="48px" height="9px" />
            </div>
          ))}
        </div>
      </section>
    </>
  );
}
