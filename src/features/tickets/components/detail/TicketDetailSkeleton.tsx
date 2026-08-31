import { FC } from 'react';
import SkeletonBlock from './SkeletonBlock';
import styles from './TicketDetailSkeleton.module.css';

// Shown while ticket detail data is being fetched. Deliberately mirrors the
// card shapes/proportions in TicketDetailPage so there's no layout shift
// when real data replaces it. Keep this in sync if TicketDetailPage's
// grid/card structure changes.
const TicketDetailSkeleton: FC = () => {
  return (
    <div className={styles.page}>
      <div className={styles.headerRow}>
        <SkeletonBlock width="180px" height="22px" />
        <SkeletonBlock width="70px" height="20px" radius="10px" />
      </div>
      <SkeletonBlock width="140px" height="12px" />

      <div className={styles.grid}>
        {/* ENFORCER & VENDOR DETAILS */}
        <div className={styles.card}>
          <SkeletonBlock width="55%" height="11px" />
          <div className={styles.divider} />
          <div className={styles.fieldGrid}>
            {Array.from({ length: 3 }).map((_, i) => (
              <div key={i} className={styles.field}>
                <SkeletonBlock width="70%" height="10px" />
                <SkeletonBlock width="90%" height="13px" />
              </div>
            ))}
          </div>
        </div>

        {/* TICKET PARAMETERS */}
        <div className={styles.card}>
          <SkeletonBlock width="50%" height="11px" />
          <div className={styles.divider} />
          <div className={styles.fieldGrid}>
            {Array.from({ length: 3 }).map((_, i) => (
              <div key={i} className={styles.field}>
                <SkeletonBlock width="60%" height="10px" />
                <SkeletonBlock width="80%" height="13px" />
              </div>
            ))}
          </div>
        </div>

        {/* VIOLATION & INSPECTION DESCRIPTION */}
        <div className={styles.splitRow}>
          <div className={styles.card}>
            <SkeletonBlock width="65%" height="11px" />
            <div className={styles.divider} />
            <div className={styles.field}>
              <SkeletonBlock width="45%" height="10px" />
              <SkeletonBlock width="85%" height="13px" />
            </div>
            <div className={styles.field}>
              <SkeletonBlock width="40%" height="10px" />
              <SkeletonBlock width="100%" height="13px" />
              <SkeletonBlock width="90%" height="13px" />
              <SkeletonBlock width="60%" height="13px" />
            </div>
            <div className={styles.field}>
              <SkeletonBlock width="50%" height="10px" />
              <SkeletonBlock width="100%" height="60px" radius="6px" />
            </div>
          </div>

          {/* PENALTY & SETTLEMENT STATUS */}
          <div className={styles.card}>
            <SkeletonBlock width="60%" height="11px" />
            <div className={styles.divider} />
            <div className={styles.field}>
              <SkeletonBlock width="40%" height="10px" />
              <SkeletonBlock width="70%" height="13px" />
            </div>
            <SkeletonBlock width="100%" height="56px" radius="8px" />
            <div className={styles.field}>
              <SkeletonBlock width="30%" height="10px" />
              <SkeletonBlock width="55%" height="13px" />
            </div>
          </div>
        </div>

        {/* VENDOR SETTLEMENT VERIFICATION */}
        <div className={`${styles.card} ${styles.full}`}>
          <SkeletonBlock width="45%" height="11px" />
          <div className={styles.divider} />
          <SkeletonBlock width="60%" height="12px" />
          <SkeletonBlock width="180px" height="72px" radius="6px" />
        </div>

        {/* UPDATE TICKET STATUS */}
        <div className={`${styles.card} ${styles.full}`}>
          <SkeletonBlock width="35%" height="11px" />
          <div className={styles.divider} />
          <SkeletonBlock width="45%" height="12px" />
          <div className={styles.statusOptions}>
            {Array.from({ length: 5 }).map((_, i) => (
              <SkeletonBlock key={i} width="100%" height="52px" radius="8px" />
            ))}
          </div>
        </div>
      </div>

      <div className={styles.footerRow}>
        <SkeletonBlock width="160px" height="12px" />
        <SkeletonBlock width="120px" height="34px" radius="6px" />
      </div>
    </div>
  );
};

export default TicketDetailSkeleton;