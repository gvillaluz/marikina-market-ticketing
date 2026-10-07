import { useMemo, useState } from "react";
import type { ViolationTrendPoint } from "@/api/types/admin-analytics.types";
import AnalyticsPanel from "./AnalyticsPanel";
import styles from "./ViolationTrendChart.module.css";

interface ViolationTrendChartProps {
  data: ViolationTrendPoint[];
  isLoading: boolean;
  isError: boolean;
  errorMessage: string;
  onRetry: () => void;
}

const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
const CHART = { left: 38, top: 12, width: 550, height: 130 };

type SeverityKey = "highSeverityCount" | "mediumSeverityCount" | "lowSeverityCount";

const SERIES: { key: SeverityKey; label: string; className: string }[] = [
  { key: "highSeverityCount", label: "High Severity", className: styles.high },
  { key: "mediumSeverityCount", label: "Medium Severity", className: styles.medium },
  { key: "lowSeverityCount", label: "Low Severity", className: styles.low },
];

export default function ViolationTrendChart({
  data,
  isLoading,
  isError,
  errorMessage,
  onRetry,
}: ViolationTrendChartProps) {
  const years = useMemo(
    () => [...new Set(data.map((point) => point.year))].sort((a, b) => b - a),
    [data],
  );
  const [selectedYear, setSelectedYear] = useState<number | null>(null);
  const year = selectedYear && years.includes(selectedYear)
    ? selectedYear
    : years[0] ?? new Date().getFullYear();
  const yearData = data.filter((point) => point.year === year);
  const monthlyValues = SERIES.map(({ key }) =>
    MONTHS.map((_, index) => yearData.find((point) => point.month === index + 1)?.[key] ?? 0),
  );
  const maxValue = Math.max(1, ...monthlyValues.flat());
  const gridMax = Math.ceil(maxValue / 5) * 5 || 5;

  function pointPosition(index: number, value: number) {
    return {
      x: CHART.left + (index / (MONTHS.length - 1)) * CHART.width,
      y: CHART.top + CHART.height - (value / gridMax) * CHART.height,
    };
  }

  return (
    <AnalyticsPanel
      title="Violation Trend Over Time"
      subtitle="Monthly violation counts by severity level."
      skeletonVariant="chart"
      isLoading={isLoading}
      isError={isError}
      errorMessage={errorMessage}
      onRetry={onRetry}
      className={styles.panel}
    >
      <div className={styles.chartContent}>
        <div className={styles.chartToolbar}>
          <span>{year} · January–December</span>
          {years.length > 1 && (
            <select
              aria-label="Select violation trend year"
              value={year}
              onChange={(event) => setSelectedYear(Number(event.target.value))}
            >
              {years.map((optionYear) => (
                <option key={optionYear} value={optionYear}>{optionYear}</option>
              ))}
            </select>
          )}
        </div>
        <svg className={styles.chart} viewBox="0 0 610 185" role="img" aria-label={`Monthly violation trends for ${year}`}>
          {Array.from({ length: 5 }).map((_, index) => {
            const y = CHART.top + (index / 4) * CHART.height;
            const label = Math.round(gridMax - (index / 4) * gridMax);
            return (
              <g key={index}>
                <line x1={CHART.left} x2={CHART.left + CHART.width} y1={y} y2={y} className={styles.gridLine} />
                <text x={CHART.left - 7} y={y + 3} textAnchor="end" className={styles.axisLabel}>{label}</text>
              </g>
            );
          })}
          {MONTHS.map((month, index) => {
            const x = CHART.left + (index / (MONTHS.length - 1)) * CHART.width;
            return (
              <text key={month} x={x} y="166" textAnchor="middle" className={styles.monthLabel}>{month}</text>
            );
          })}
          {SERIES.map((series) => {
            const values = MONTHS.map((_, index) =>
              yearData.find((point) => point.month === index + 1)?.[series.key] ?? 0,
            );
            const points = values
              .map((count, index) => {
                const position = pointPosition(index, count);
                return `${position.x},${position.y}`;
              })
              .join(" ");
            return (
              <g key={series.key} className={series.className}>
                <polyline points={points} className={styles.trendLine} />
                {values.map((count, index) => {
                  const position = pointPosition(index, count);
                  return <circle key={index} cx={position.x} cy={position.y} r="2.6" className={styles.point} />;
                })}
              </g>
            );
          })}
        </svg>
        <div className={styles.legend}>
          {SERIES.map((series) => (
            <span key={series.key} className={series.className}>
              <i aria-hidden="true" />{series.label}
            </span>
          ))}
        </div>
      </div>
    </AnalyticsPanel>
  );
}
