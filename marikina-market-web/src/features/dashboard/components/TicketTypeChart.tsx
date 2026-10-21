import { FC } from 'react';
import styles from './TicketTypeChart.module.css';

interface TicketTypeChartProps {
  data: { label: string; value: number }[];
}

const COLORS = ['var(--primary-500)', 'var(--secondary-400)', 'var(--info)', 'var(--success)'];

const TicketTypeChart: FC<TicketTypeChartProps> = ({ data }) => {
  const total = data.reduce((sum, d) => sum + d.value, 0) || 1;

  return (
    <div className={styles.chart}>
      <div className={styles.bars}>
        {data.map((item, i) => {
          const height = Math.max(4, (item.value / total) * 100);
          return (
            <div key={item.label} className={styles.barCol}>
              <div className={styles.barTrack}>
                <div
                  className={styles.bar}
                  style={{ height: `${height}%`, background: COLORS[i % COLORS.length] }}
                />
              </div>
              <span className={styles.barLabel}>{item.label}</span>
              <span className={styles.barValue}>{item.value}</span>
            </div>
          );
        })}
      </div>
    </div>
  );
};

export default TicketTypeChart;
