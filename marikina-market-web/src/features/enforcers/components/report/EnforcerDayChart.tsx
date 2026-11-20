import type { EnforcerReportDate } from "@/api/types/enforcer.types";
import { formatNumber } from "@/utils/formatters";
import {
  chartBars,
  formatReportPeriod,
  type ReportPeriod,
} from "../../enforcerReport.utils";
import styles from "./EnforcerDayChart.module.css";

const records = (count: number) =>
  `${formatNumber(count)} record${count === 1 ? "" : "s"}`;

// Records over the period. The bars are a picture only; the table below it carries the numbers.
export default function EnforcerDayChart({
  days,
  period,
}: {
  days: EnforcerReportDate[];
  period: ReportPeriod;
}) {
  const { unit, bars } = chartBars(days, period);
  const max = Math.max(...bars.map((bar) => bar.total), 0);
  const busiest = bars.find((bar) => bar.total === max && max > 0);
  const first = bars[0];
  const last = bars[bars.length - 1];
  return (
    <figure className={styles.chart}>
      <figcaption className={styles.caption}>
        {unit === "day" ? "One bar per day" : "One bar per week (Monday to Sunday)"}
        {busiest &&
          ` · busiest: ${formatReportPeriod(busiest)}, ${records(busiest.total)}`}
      </figcaption>
      <div className={styles.plot} aria-hidden="true">
        <span className={styles.max}>{formatNumber(max)}</span>
        <div className={styles.bars}>
          {bars.map((bar) => (
            <span
              key={bar.from}
              data-bar
              className={bar === busiest ? styles.peak : styles.bar}
              title={`${formatReportPeriod(bar)}: ${records(bar.total)}`}
              style={{ height: max === 0 ? 0 : `${(bar.total / max) * 100}%` }}
            />
          ))}
        </div>
      </div>
      {first && (
        <div className={styles.axis} aria-hidden="true">
          <span>{formatReportPeriod({ from: first.from, to: first.from })}</span>
          <span>{formatReportPeriod({ from: last.to, to: last.to })}</span>
        </div>
      )}
    </figure>
  );
}
