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
          {Array.from({ length: 5 }).map((_, i) => (
            <SkeletonBlock key={i} width="100%" height="18px" />
          ))}
        </div>
      </div>
    </>
  );
};

export default EnforcerActivitySkeleton;