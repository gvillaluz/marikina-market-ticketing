import { FC } from 'react';
import SkeletonBlock from '../../../components/ui/Skeleton/SkeletonBlock';
import styles from './EnforcerCard.module.css';

const EnforcerCardSkeleton: FC = () => {
  return (
    <div className={styles.card}>
      <div className={styles.header}>
        <SkeletonBlock width="36px" height="36px" radius="50%" />
        <div className={styles.identity}>
          <SkeletonBlock width="120px" height="14px" />
          <SkeletonBlock width="90px" height="10px" />
          <SkeletonBlock width="60px" height="16px" radius="10px" />
        </div>
      </div>
      <div className={styles.stats}>
        <SkeletonBlock width="100%" height="46px" radius="6px" />
        <SkeletonBlock width="100%" height="46px" radius="6px" />
      </div>
      <SkeletonBlock width="100%" height="34px" radius="6px" />
    </div>
  );
};

export default EnforcerCardSkeleton;