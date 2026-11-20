import type {
  EnforcerReport,
  EnforcerReportTotals,
} from "@/api/types/enforcer.types";
import { formatDate } from "@/utils/formatters";
import { manilaDay, type ExportColumn } from "@/utils/tableExport";

export type ReportPeriodPreset = "today" | "week" | "month";

export interface ReportPeriod {
  from: string;
  to: string;
}

export const REPORT_PERIOD_PRESETS: {
  value: ReportPeriodPreset;
  label: string;
}[] = [
  { value: "today", label: "Today" },
  { value: "week", label: "This week" },
  { value: "month", label: "This month" },
];

// "today" is a Philippine calendar day (YYYY-MM-DD). Weeks start on Monday, as on the phone.
export function reportPeriodPreset(
  preset: ReportPeriodPreset,
  today: string,
): ReportPeriod {
  if (preset === "today") return { from: today, to: today };
  if (preset === "month") return { from: `${today.slice(0, 7)}-01`, to: today };
  const monday = new Date(`${today}T00:00:00Z`);
  monday.setUTCDate(monday.getUTCDate() - ((monday.getUTCDay() + 6) % 7));
  return { from: monday.toISOString().slice(0, 10), to: today };
}

export function isPresetPeriod(
  preset: ReportPeriodPreset,
  period: ReportPeriod,
  today: string,
): boolean {
  const dates = reportPeriodPreset(preset, today);
  return dates.from === period.from && dates.to === period.to;
}

function isReportDate(value: string): boolean {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
  const date = new Date(`${value}T00:00:00Z`);
  return (
    Number.isFinite(date.getTime()) && date.toISOString().slice(0, 10) === value
  );
}

export function validateReportPeriod(
  period: ReportPeriod,
  today: string,
): string {
  if (!isReportDate(period.from) || !isReportDate(period.to))
    return "Choose a valid From and To date.";
  if (period.from > period.to)
    return "The To date must be on or after the From date.";
  if (period.to > today) return "Choose dates on or before today.";
  return "";
}

// A moment as its Philippine calendar date, e.g. "Nov 5, 2026".
export function formatManilaDate(value: string): string {
  return formatDate(value, { timeZone: "Asia/Manila" });
}

export function formatReportPeriod(period: ReportPeriod): string {
  const from = formatManilaDate(`${period.from}T00:00:00+08:00`);
  const to = formatManilaDate(`${period.to}T00:00:00+08:00`);
  return from === to ? from : `${from} – ${to}`;
}

interface EnforcerReportLine extends EnforcerReportTotals {
  enforcer: string;
  username: string;
  status: string;
  daysWithRecords: string;
  lastRecord: string;
}

// One line per enforcer, then the total line (which has no days or last record).
export function enforcerReportLines(
  report: EnforcerReport,
): EnforcerReportLine[] {
  return [
    ...report.enforcers.map((row) => ({
      ...row,
      enforcer: `${row.lastName}, ${row.firstName}`,
      daysWithRecords: String(row.daysWithRecords),
      lastRecord: row.lastRecordAt ? manilaDay(row.lastRecordAt) : "",
    })),
    {
      ...report.totals,
      enforcer: "Total",
      username: "",
      status: "",
      daysWithRecords: "",
      lastRecord: "",
    },
  ];
}

export const ENFORCER_REPORT_COLUMNS: ExportColumn<EnforcerReportLine>[] = [
  { key: "enforcer", header: "Enforcer", value: (line) => line.enforcer },
  { key: "username", header: "Username", value: (line) => line.username },
  { key: "status", header: "Status", value: (line) => line.status },
  { key: "warnings", header: "Warnings", value: (line) => String(line.warnings) },
  { key: "tickets", header: "Tickets", value: (line) => String(line.tickets) },
  {
    key: "totalRecords",
    header: "Total records",
    value: (line) => String(line.totalRecords),
  },
  {
    key: "settledTickets",
    header: "Settled tickets",
    value: (line) => String(line.settledTickets),
  },
  {
    key: "openTickets",
    header: "Open tickets",
    value: (line) => String(line.openTickets),
  },
  {
    key: "finesCharged",
    header: "Fines charged (PHP)",
    value: (line) => line.finesCharged.toFixed(2),
  },
  {
    key: "finesSettled",
    header: "Fines settled (PHP)",
    value: (line) => line.finesSettled.toFixed(2),
  },
  {
    key: "daysWithRecords",
    header: "Days with records",
    value: (line) => line.daysWithRecords,
  },
  { key: "lastRecord", header: "Last record", value: (line) => line.lastRecord },
];
