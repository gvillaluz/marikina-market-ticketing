import { FC } from 'react';
import styles from './FineSummaryBox.module.css';

interface FineSummaryBoxProps {
  amount: string;
}

const FineSummaryBox: FC<FineSummaryBoxProps> = ({ amount }) => {
  return (
    <div className={styles.box}>
      <span className={styles.label}>Total Fine Due:</span>
      <span className={styles.amount}>{amount}</span>
    </div>
  );
};

export default FineSummaryBox;