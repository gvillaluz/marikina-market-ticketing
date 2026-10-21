import { FC } from 'react';
import SkeletonBlock from '@/components/ui/Skeleton/SkeletonBlock';
import styles from './TicketModalSkeleton.module.css';

const TicketModalSkeleton: FC = () => {
  return (
    <div className={styles.ticketPaper}>
      <div className={styles.ticketHeader}>
        <SkeletonBlock width="160px" height="16px" />
        <SkeletonBlock width="200px" height="12px" />
      </div>

      <div className={styles.ticketTop}>
        <div className={styles.brand}>
          <SkeletonBlock width="55px" height="55px" radius="50%" />
          <SkeletonBlock width="150px" height="18px" />
        </div>
        <div className={styles.controlNo}>
          <SkeletonBlock width="70px" height="10px" />
          <SkeletonBlock width="80px" height="20px" />
        </div>
      </div>

      <div className={styles.divider} />

      <div className={styles.section}>
        <SkeletonBlock width="45%" height="11px" />
        <div className={styles.fieldGrid}>
          {Array.from({ length: 4 }).map((_, i) => (
            <div key={i} className={styles.field}>
              <SkeletonBlock width="70%" height="10px" />
              <SkeletonBlock width="90%" height="13px" />
            </div>
          ))}
        </div>
      </div>

      <div className={styles.section}>
        <SkeletonBlock width="55%" height="11px" />
        <SkeletonBlock width="100%" height="48px" radius="6px" />
        <SkeletonBlock width="100%" height="48px" radius="6px" />
      </div>

      <div className={styles.section}>
        <SkeletonBlock width="50%" height="11px" />
        <SkeletonBlock width="100%" height="56px" radius="8px" />
      </div>

      <div className={styles.signatureRow}>
        <div className={styles.signatureField}>
          <SkeletonBlock width="100%" height="1px" />
          <SkeletonBlock width="60%" height="12px" />
        </div>
        <div className={styles.signatureField}>
          <SkeletonBlock width="100%" height="1px" />
          <SkeletonBlock width="60%" height="12px" />
        </div>
      </div>
    </div>
  );
};

export default TicketModalSkeleton;