import { FC } from 'react';
import styles from './MonthlyTrendChart.module.css';

interface MonthlyTrendChartProps {
  data: { month: string; tickets: number; resolved: number }[];
}

const MonthlyTrendChart: FC<MonthlyTrendChartProps> = ({ data }) => {
  const max = Math.max(...data.map((d) => Math.max(d.tickets, d.resolved)), 1);

  return (
    <div className={styles.chart}>
      <div className={styles.chartWrap}>
        {data.map((d) => (
          <div key={d.month} className={styles.col}>
            <div className={styles.bars}>
              <div
                className={`${styles.bar} ${styles.tickets}`}
                style={{ height: `${(d.tickets / max) * 100}%` }}
              />
              <div
                className={`${styles.bar} ${styles.resolved}`}
                style={{ height: `${(d.resolved / max) * 100}%` }}
              />
            </div>
            <span className={styles.month}>{d.month}</span>
          </div>
        ))}
      </div>
      <div className={styles.legend}>
        <span><i className={`${styles.dot} ${styles.tickets}`} /> Created</span>
        <span><i className={`${styles.dot} ${styles.resolved}`} /> Resolved</span>
      </div>
    </div>
  );
};

export default MonthlyTrendChart;
