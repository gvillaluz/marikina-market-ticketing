import type {
  EnforcerActivityReport,
  EnforcerMarketStreet,
  EnforcerPenaltyKind,
  EnforcerRecordCount,
  EnforcerReport,
  EnforcerReportDate,
  EnforcerReportRow,
  EnforcerReportTotals,
  EnforcerViolationType,
} from "@/api/types/enforcer.types";
import type { PenaltyType, TicketCategories } from "@/api/types/ticket.types";
import { formatDate } from "@/utils/formatters";
import {
  csvLine,
  manilaDay,
  toCsv,
  type ExportColumn,
} from "@/utils/tableExport";

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

function reportLine(row: EnforcerReportRow): EnforcerReportLine {
  return {
    ...row,
    enforcer: `${row.lastName}, ${row.firstName}`,
    daysWithRecords: String(row.daysWithRecords),
    lastRecord: row.lastRecordAt ? manilaDay(row.lastRecordAt) : "",
  };
}

// One line per enforcer, then the total line (which has no days or last record).
export function enforcerReportLines(
  report: EnforcerReport,
): EnforcerReportLine[] {
  return [
    ...report.enforcers.map(reportLine),
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

const PENALTY_LABELS: Record<PenaltyType, string> = {
  CashFine: "Cash fine",
  BloodDonation: "Blood donation",
  CommunityService: "Community service",
};

// Same wording as the Ordinances page; Licensing and Noise are older types.
const VIOLATION_TYPE_LABELS: Record<TicketCategories, string> = {
  Traffic: "Traffic",
  Obstruction: "Obstruction",
  Sanitation: "Sanitation",
  Licensing: "Licensing",
  Noise: "Noise",
  WeightMeasures: "Weights & Measures",
  DressCode: "Dress Code",
  IllegalVendor: "Illegal Vendor",
  NonSmoking: "Non-Smoking",
  Others: "Others",
};

export const NOT_RECORDED = "Not recorded";

export function penaltyKindLabel(penaltyType: PenaltyType | null): string {
  return penaltyType ? PENALTY_LABELS[penaltyType] : NOT_RECORDED;
}

export function violationTypeLabel(category: TicketCategories | null): string {
  return category ? VIOLATION_TYPE_LABELS[category] : NOT_RECORDED;
}

// Share of all the enforcer's records, as a whole percent.
export function sharePercent(count: number, totalRecords: number): number {
  return totalRecords === 0 ? 0 : Math.round((count / totalRecords) * 100);
}

export interface ChartBar extends EnforcerRecordCount {
  from: string;
  to: string;
}

const MAX_DAILY_BARS = 62;

function addDays(day: string, count: number): string {
  const date = new Date(`${day}T00:00:00Z`);
  date.setUTCDate(date.getUTCDate() + count);
  return date.toISOString().slice(0, 10);
}

// One bar per day (days with no records included). Over 62 days, one bar per Monday-to-Sunday
// week, cut to the period at both ends.
export function chartBars(
  days: EnforcerReportDate[],
  period: ReportPeriod,
): { unit: "day" | "week"; bars: ChartBar[] } {
  const byDay = new Map(days.map((day) => [day.date, day]));
  const allDays: string[] = [];
  for (let day = period.from; day <= period.to; day = addDays(day, 1))
    allDays.push(day);
  const unit = allDays.length > MAX_DAILY_BARS ? "week" : "day";
  const bars: ChartBar[] = [];
  for (const day of allDays) {
    const startsBar =
      unit === "day" ||
      day === period.from ||
      new Date(`${day}T00:00:00Z`).getUTCDay() === 1;
    if (startsBar)
      bars.push({ from: day, to: day, warnings: 0, tickets: 0, total: 0 });
    const bar = bars[bars.length - 1];
    const counts = byDay.get(day);
    bar.to = day;
    bar.warnings += counts?.warnings ?? 0;
    bar.tickets += counts?.tickets ?? 0;
    bar.total += counts?.total ?? 0;
  }
  return { unit, bars };
}

function csvTable<T>(
  title: string,
  columns: ExportColumn<T>[],
  rows: T[],
): string {
  return `${csvLine([title])}\r\n${toCsv(columns, rows)}`;
}

function countColumns<T extends EnforcerRecordCount>(
  label: string,
  name: (row: T) => string,
  totalRecords?: number,
): ExportColumn<T>[] {
  const columns: ExportColumn<T>[] = [
    { key: "name", header: label, value: name },
    { key: "warnings", header: "Warnings", value: (row) => String(row.warnings) },
    { key: "tickets", header: "Tickets", value: (row) => String(row.tickets) },
    { key: "total", header: "Total", value: (row) => String(row.total) },
  ];
  if (totalRecords === undefined) return columns;
  return [
    ...columns,
    {
      key: "share",
      header: "Share of records (%)",
      value: (row) => String(sharePercent(row.total, totalRecords)),
    },
  ];
}

const PENALTY_COLUMNS: ExportColumn<EnforcerPenaltyKind>[] = [
  {
    key: "penaltyType",
    header: "Penalty kind",
    value: (row) => penaltyKindLabel(row.penaltyType),
  },
  { key: "tickets", header: "Tickets", value: (row) => String(row.tickets) },
  {
    key: "settledTickets",
    header: "Settled tickets",
    value: (row) => String(row.settledTickets),
  },
  {
    key: "openTickets",
    header: "Open tickets",
    value: (row) => String(row.openTickets),
  },
  {
    key: "finesCharged",
    header: "Fines charged (PHP)",
    value: (row) => row.finesCharged.toFixed(2),
  },
];

// One file for the one-enforcer report: who and when, then each table under its title.
export function enforcerActivityCsv(report: EnforcerActivityReport): string {
  const { enforcer } = report;
  const totalRecords = enforcer.totalRecords;
  return [
    [
      csvLine(["Enforcer", `${enforcer.lastName}, ${enforcer.firstName}`]),
      csvLine(["Username", enforcer.username]),
      csvLine(["From", report.dateRange.from]),
      csvLine(["To", report.dateRange.to]),
    ].join("\r\n"),
    csvTable("Summary", ENFORCER_REPORT_COLUMNS.slice(3), [
      reportLine(enforcer),
    ]),
    csvTable("Penalty kind", PENALTY_COLUMNS, report.penaltyKinds),
    csvTable(
      "Violation type",
      countColumns<EnforcerViolationType>(
        "Violation type",
        (row) => violationTypeLabel(row.category),
        totalRecords,
      ),
      report.violationTypes,
    ),
    csvTable(
      "Market street",
      countColumns<EnforcerMarketStreet>(
        "Market street",
        (row) => row.marketSectionName,
        totalRecords,
      ),
      report.marketStreets,
    ),
    csvTable(
      "Records per day",
      countColumns<EnforcerReportDate>("Date", (row) => row.date),
      report.days,
    ),
  ].join("\r\n\r\n");
}
