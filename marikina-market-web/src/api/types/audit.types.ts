import type { UserRole } from "./common.types";

export type AuditModule =
  | "Users"
  | "Vendors"
  | "Tickets"
  | "Ordinances"
  | "MarketSections"
  | "Security"
  | "Reports"
  | "Backups"
  | "Notifications"
  | "AuditLogs";
export type AuditResult = "Success" | "Failed";
export type AuditDateRange =
  | "AllTime"
  | "Today"
  | "Yesterday"
  | "Last7Days"
  | "Last30Days"
  | "ThisMonth"
  | "LastMonth";

export interface AuditFilters {
  modules?: readonly AuditModule[];
  results?: readonly AuditResult[];
  dateRange?: AuditDateRange;
  search?: string;
  userId?: number;
  role?: UserRole;
}

export interface AuditLogSummary {
  id: number;
  timestamp: string;
  userId: number | null;
  firstName: string | null;
  lastName: string | null;
  role: UserRole | null;
  action: string;
  module: AuditModule;
  result: AuditResult;
}

export interface AuditLogDetail extends AuditLogSummary {
  targetId: string | null;
  details: string | null;
}

export interface AuditPageResponse {
  items: AuditLogSummary[];
  hasMore: boolean;
  total: number;
}

export interface AuditCounts {
  recordedActivities: number;
  successfulActions: number;
  securityEvents: number;
}
