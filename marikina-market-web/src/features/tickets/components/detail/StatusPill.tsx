import { FC, ReactNode } from 'react';
import styles from './StatusPill.module.css';
import { RecordStatus, Severity } from '@/api/types/common.types';

interface StatusPillProps {
  variant: string;
  children: ReactNode;
  dot?: boolean;
}

const StatusPill: FC<StatusPillProps> = ({ variant, children, dot }) => {
  if (dot) {
    return (
      <div className={`${styles.status} ${styles[variant.toLowerCase()]}`}>
        <span className={styles.dot} />
        <span>{children}</span>
      </div>
    );
  }
  return <span className={`${styles.pill} ${styles[variant.toLowerCase()]}`}>{children}</span>;
};

export default StatusPill;