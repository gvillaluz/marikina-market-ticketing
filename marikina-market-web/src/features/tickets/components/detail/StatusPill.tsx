import { FC, ReactNode } from 'react';
import styles from './StatusPill.module.css';

interface StatusPillProps {
  variant: string;
  children: ReactNode;
}

const StatusPill: FC<StatusPillProps> = ({ variant, children }) => (
  <div className={`${styles.status} ${styles[variant.toLowerCase()]}`}>
    <span className={styles.dot} />
    <span>{children}</span>
  </div>
);

export default StatusPill;
