import type {
  ReportDocument,
  ReportHistoryItem,
  ReportHistoryResponse,
  ReportMetric,
  ReportBreakdown,
  ReportPreview,
  ReportSummary,
  ReportType,
  SavedReport,
} from "../types/reports.types";
import { ApiRequestError } from "@/utils/apiErrors";

function object(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}
function date(value: unknown): value is string {
  if (typeof value !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(value))
    return false;
  const parsed = new Date(`${value}T00:00:00Z`);
  return (
    Number.isFinite(parsed.getTime()) &&
    parsed.toISOString().slice(0, 10) === value
  );
}
function metric(value: unknown): value is ReportMetric {
  return (
    object(value) &&
    Number.isSafeInteger(value.totalRecords) &&
    Number(value.totalRecords) >= 0 &&
    typeof value.assessedPenalties === "number" &&
    Number.isFinite(value.assessedPenalties) &&
    value.assessedPenalties >= 0
  );
}
function breakdown(value: unknown): value is ReportBreakdown {
  return (
    object(value) &&
    metric(value.total) &&
    metric(value.resolved) &&
    metric(value.pending)
  );
}
function base(
  value: unknown,
): value is Pick<ReportPreview, "type" | "dateRange"> &
  Record<string, unknown> {
  return (
    object(value) &&
    typeof value.type === "string" &&
    ["Warning", "Ticket", "Warning & Ticket"].includes(value.type) &&
    object(value.dateRange) &&
    date(value.dateRange.from) &&
    date(value.dateRange.to) &&
    value.dateRange.from <= value.dateRange.to
  );
}
function history(value: unknown): value is ReportHistoryItem {
  return (
    base(value) &&
    Number.isSafeInteger(value.id) &&
    Number(value.id) > 0 &&
    typeof value.dateGenerated === "string" &&
    Number.isFinite(Date.parse(value.dateGenerated)) &&
    object(value.generatedBy) &&
    Number.isSafeInteger(value.generatedBy.id) &&
    Number(value.generatedBy.id) > 0 &&
    typeof value.generatedBy.name === "string"
  );
}
export function validateReport(value: unknown, saved: true): SavedReport;
export function validateReport(value: unknown, saved: false): ReportPreview;
export function validateReport(value: unknown, saved: boolean): ReportDocument {
  if (!base(value) || !summary(value.summary, value.type))
    throw new ApiRequestError();
  if (saved) {
    if (!history(value)) throw new ApiRequestError();
    return {
      id: value.id,
      type: value.type,
      dateRange: value.dateRange,
      dateGenerated: value.dateGenerated,
      generatedBy: value.generatedBy,
      summary: value.summary,
    };
  }
  return {
    type: value.type,
    dateRange: value.dateRange,
    summary: value.summary,
  };
}
function summary(value: unknown, type: ReportType): value is ReportSummary {
  return (
    breakdown(value) &&
    object(value) &&
    (type === "Ticket"
      ? value.warningsIssued === null
      : breakdown(value.warningsIssued)) &&
    (type === "Warning"
      ? value.ticketsIssued === null
      : breakdown(value.ticketsIssued))
  );
}
export function validateReportHistory(value: unknown): ReportHistoryResponse {
  if (
    !object(value) ||
    !Array.isArray(value.items) ||
    !value.items.every(history) ||
    (value.hasMore === true && value.items.length === 0) ||
    typeof value.hasMore !== "boolean" ||
    !Number.isSafeInteger(value.total) ||
    Number(value.total) < value.items.length
  )
    throw new ApiRequestError();
  return value as unknown as ReportHistoryResponse;
}
