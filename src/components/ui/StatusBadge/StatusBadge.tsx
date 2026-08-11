import { FC } from 'react';
import { STATUS_LABELS } from '@/utils/constants';
import type { Status } from '@/api/types/common.types';
import styles from './StatusBadge.module.css';

interface StatusBadgeProps {
  status: Status;
}

const StatusBadge: FC<StatusBadgeProps> = ({ status }) => {
  return (
    <span className={`${styles.badge} ${styles[status] ?? ''}`}>
      <span className={styles.dot} />
      {STATUS_LABELS[status] ?? status}
    </span>
  );
};

export default StatusBadge;
