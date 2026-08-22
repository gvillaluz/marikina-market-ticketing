import { FC } from 'react';
import { STATUS_LABELS } from '@/utils/constants';
import styles from './StatusBadge.module.css';

interface StatusBadgeProps {
  status: string;
}

const StatusBadge: FC<StatusBadgeProps> = ({ status }) => {
  const normalized = status.toLowerCase();
  const label = STATUS_LABELS[normalized as keyof typeof STATUS_LABELS] ?? normalized;
  return (
    <span className={`${styles.badge} ${styles[normalized] ?? ''}`}>
      <span className={styles.dot} />
      {label}
    </span>
  );
};

export default StatusBadge;
