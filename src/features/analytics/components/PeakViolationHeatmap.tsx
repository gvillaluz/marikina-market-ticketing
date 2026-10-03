import type { PeakViolationTime } from "@/api/types/admin-analytics.types";
import AnalyticsPanel from "./AnalyticsPanel";
import styles from "./PeakViolationHeatmap.module.css";

interface PeakViolationHeatmapProps {
  data: PeakViolationTime[];
  isLoading: boolean;
  isError: boolean;
  errorMessage: string;
  onRetry: () => void;
}

const WEEKDAYS = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
const HEAT_LEVELS = [
  { level: 0, label: "Low" },
  { level: 1, label: "Moderate" },
  { level: 2, label: "High" },
  { level: 3, label: "Peak" },
];

function dayOrder(day: PeakViolationTime): number {
  const labelIndex = WEEKDAYS.findIndex(
    (weekday) => weekday.toLowerCase() === day.day.toLowerCase(),
  );
  if (labelIndex >= 0) return labelIndex;
  return (day.dayOfWeek + 6) % 7;
}

export default function PeakViolationHeatmap({
  data,
  isLoading,
  isError,
  errorMessage,
  onRetry,
}: PeakViolationHeatmapProps) {
  const timeBlocks = [...new Map(data.map((item) => [item.timeBlock, item.timeRange])).entries()]
    .sort(([first], [second]) => first - second);
  const days = [...new Map(data.map((item) => [item.dayOfWeek, item])).values()]
    .sort((first, second) => dayOrder(first) - dayOrder(second));
  const maxCount = Math.max(1, ...data.map((item) => item.ticketCount));

  function getCellLevel(count: number): number {
    if (count <= 0) return 0;
    const ratio = count / maxCount;
    if (ratio >= 0.75) return 3;
    if (ratio >= 0.45) return 2;
    return 1;
  }

  return (
    <AnalyticsPanel
      title="Peak Violation Time Analysis"
      subtitle="Violation activity by day of week and time block."
      skeletonVariant="heatmap"
      isLoading={isLoading}
      isError={isError}
      errorMessage={errorMessage}
      onRetry={onRetry}
      className={styles.panel}
    >
      <div className={styles.content}>
        <div className={styles.heatmapWrap}>
          <table className={styles.heatmap}>
            <thead>
              <tr>
                <th scope="col">Day</th>
                {timeBlocks.map(([timeBlock, timeRange]) => (
                  <th scope="col" key={timeBlock}>{timeRange}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {days.map((day) => (
                <tr key={day.dayOfWeek}>
                  <th scope="row">{day.day.slice(0, 3)}</th>
                  {timeBlocks.map(([timeBlock]) => {
                    const cell = data.find(
                      (item) =>
                        item.dayOfWeek === day.dayOfWeek &&
                        item.timeBlock === timeBlock,
                    );
                    const count = cell?.ticketCount ?? 0;
                    const level = getCellLevel(count);
                    return (
                      <td
                        key={timeBlock}
                        className={styles[`heat${level}`]}
                        title={`${day.day}, ${cell?.timeRange ?? ""}: ${count} violations`}
                      >
                        {count}
                      </td>
                    );
                  })}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <div className={styles.legend} aria-label="Heat map legend">
          <span>Fewer violations</span>
          {HEAT_LEVELS.map(({ level, label }) => (
            <span key={label} className={styles.legendLevel}>
              <i className={styles[`heat${level}`]} aria-hidden="true" />{label}
            </span>
          ))}
          <span>More violations</span>
        </div>
      </div>
    </AnalyticsPanel>
  );
}
