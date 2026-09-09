import { FC } from "react";
import styles from "./MonthlyInspectionsChart.module.css";
import { MonthlyInspection } from "@/api/types/enforcer.types";

interface MonthlyInspectionsChartProps {
  inspections: MonthlyInspection[];
}

const MONTH_NAMES = [
  "Jan",
  "Feb",
  "Mar",
  "Apr",
  "May",
  "Jun",
  "Jul",
  "Aug",
  "Sep",
  "Oct",
  "Nov",
  "Dec",
];

const MonthlyInspectionsChart: FC<MonthlyInspectionsChartProps> = ({
  inspections,
}) => {
  console.log(inspections);
  const max = Math.max(...inspections.map((d) => d.totalIssuedTickets), 1);
  const currentMonthNumber = new Date().getMonth() + 1;

  return (
    <div className={styles.card}>
      <span className={styles.title}>MONTHLY INSPECTIONS</span>
      <div className={styles.bars}>
        {inspections.map((d) => (
          <div key={d.month} className={styles.barColumn}>
            <span className={styles.count}>{d.totalIssuedTickets}</span>
            <div className={styles.barTrack}>
              <div
                className={`${styles.bar} ${currentMonthNumber === d.month ? styles.barHighlight : ""}`}
                style={{
                  height: `${Math.max((d.totalIssuedTickets / max) * 100, 3)}%`,
                }}
              />
            </div>
            <span className={styles.month}>{MONTH_NAMES[d.month - 1]}</span>
          </div>
        ))}
      </div>
    </div>
  );
};

export default MonthlyInspectionsChart;
