import { FC } from "react";
import styles from "./MonthlyInspectionsChart.module.css";

interface MonthlyInspectionsChartProps {
  data: { month: string; count: number }[];
}

const MonthlyInspectionsChart: FC<MonthlyInspectionsChartProps> = ({
  data,
}) => {
  const max = Math.max(...data.map((d) => d.count), 1);
  const highestIndex = data.reduce(
    (best, d, i) => (d.count > data[best].count ? i : best),
    0,
  );

  return (
    <div className={styles.card}>
      <span className={styles.title}>MONTHLY INSPECTIONS</span>
      <div className={styles.bars}>
        {data.map((d, i) => (
          <div key={d.month} className={styles.barColumn}>
            <span className={styles.count}>{d.count}</span>
            <div
              className={`${styles.bar} ${i === highestIndex ? styles.barHighlight : ""}`}
              style={{ height: `${(d.count / max) * 100}%` }}
            />
            <span className={styles.month}>{d.month}</span>
          </div>
        ))}
      </div>
    </div>
  );
};

export default MonthlyInspectionsChart;
