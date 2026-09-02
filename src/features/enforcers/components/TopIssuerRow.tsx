import { FC } from 'react';
import styles from './TopIssuerRow.module.css';

interface TopIssuerRowProps {
  rank: number;
  name: string;
  count: number;
}

const TopIssuerRow: FC<TopIssuerRowProps> = ({ rank, name, count }) => {
  return (
    <div className={styles.row}>
      <span className={styles.rank}>{rank}</span>
      <span className={styles.name}>{name}</span>
      <span className={styles.count}>{count} tickets</span>
    </div>
  );
};

export default TopIssuerRow;