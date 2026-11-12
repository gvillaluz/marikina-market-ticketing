import { peakHours, type RiskTone } from "../recommendations.format";
import styles from "./HourlyBars.module.css";

interface HourlyBarsProps {
  hourlyCounts: number[];
  peakStartHour: number;
  tone: RiskTone;
}

export default function HourlyBars({
  hourlyCounts,
  peakStartHour,
  tone,
}: HourlyBarsProps) {
  const counts = Array.from(
    { length: 24 },
    (_, hour) => hourlyCounts[hour] ?? 0,
  );
  const highest = Math.max(1, ...counts);
  const peak = peakHours(peakStartHour);

  return (
    <div className={`${styles.bars} ${styles[tone]}`} aria-hidden="true">
      {counts.map((count, hour) => (
        <span
          key={hour}
          className={`${styles.bar} ${peak.includes(hour) ? styles.peak : ""}`}
          style={{ height: `${(count / highest) * 100}%` }}
        />
      ))}
    </div>
  );
}
