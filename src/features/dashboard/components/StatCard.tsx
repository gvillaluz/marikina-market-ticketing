import { FC } from 'react';
import styles from './StatCard.module.css';

interface StatCardProps {
  label: string;
  value: string | number;
  icon?: string;
  trend?: string;
  trendUp?: boolean;
  tone?: 'primary' | 'success' | 'warning' | 'danger' | 'info';
}

const StatCard: FC<StatCardProps> = ({ label, value, icon, trend, trendUp, tone = 'primary' }) => {
  return (
    <div className={styles.card}>
      <div className={styles.top}>
        <span className={`${styles.icon} ${styles[tone]}`}>{icon}</span>
        {trend && (
          <span className={`${styles.trend} ${trendUp ? styles.up : styles.down}`}>
            {trendUp ? '↑' : '↓'} {trend}
          </span>
        )}
      </div>
      <p className={styles.value}>{value}</p>
      <p className={styles.label}>{label}</p>
    </div>
  );
};

export default StatCard;
