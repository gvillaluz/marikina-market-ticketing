import { FC } from 'react';
import SkeletonBlock from '@/components/ui/Skeleton/SkeletonBlock'; // reuse existing shimmer primitive
import styles from './EnforcerActivityPanel.module.css';

const EnforcerActivitySkeleton: FC = () => {
  return (
    <>
      <div className={styles.statsRow}>
        <div className={styles.statBox}>
          <SkeletonBlock width="40%" height="28px" />
          <SkeletonBlock width="70%" height="10px" />
        </div>
        <div className={styles.statBox}>
          <SkeletonBlock width="40%" height="28px" />
          <SkeletonBlock width="70%" height="10px" />
        </div>
      </div>

      <div className={styles.section}>
        <SkeletonBlock width="50%" height="12px" />
        <div className={styles.issuerList}>
          {Array.from({ length: 5 }).map((_, index) => (
            <div className={styles.skeletonIssuer} key={index}>
              <SkeletonBlock width="27px" height="27px" radius="50%" />
              <div className={styles.skeletonIssuerInfo}>
                <SkeletonBlock width="62%" height="11px" />
                <SkeletonBlock width="38%" height="9px" />
              </div>
              <SkeletonBlock width="30px" height="11px" />
            </div>
          ))}
        </div>
      </div>
    </>
  );
};

export default EnforcerActivitySkeleton;