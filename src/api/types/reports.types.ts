import type { PaginatedResponse } from "./common.types";

export type ReportType = "Warning" | "Ticket" | "Warning & Ticket";
export interface ReportDateRange {
  from: string;
  to: string;
}
export interface GenerateReportInput extends ReportDateRange {
  type: ReportType;
}
export interface ReportMetric {
  totalRecords: number;
  assessedPenalties: number;
}
export interface ReportBreakdown {
  total: ReportMetric;
  resolved: ReportMetric;
  pending: ReportMetric;
}
export interface ReportSummary extends ReportBreakdown {
  warningsIssued: ReportBreakdown | null;
  ticketsIssued: ReportBreakdown | null;
}
export interface ReportPreview {
  type: ReportType;
  dateRange: ReportDateRange;
  summary: ReportSummary;
}
export interface ReportHistoryItem {
  id: number;
  type: ReportType;
  dateRange: ReportDateRange;
  dateGenerated: string;
  generatedBy: { id: number; name: string };
}
export interface SavedReport extends ReportHistoryItem {
  summary: ReportSummary;
}
export type ReportDocument = ReportPreview | SavedReport;
export type ReportHistoryResponse = PaginatedResponse<ReportHistoryItem>;
