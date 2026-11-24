import type {
  DashboardActivity,
  DashboardMetrics,
  DashboardOverdueTicket,
  DashboardOverdueTickets,
  DashboardSummary,
} from "@/api/types/dashboard.types";
import { ApiRequestError } from "@/utils/apiErrors";

const OVERDUE_TICKET_LIMIT = 5;

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function isNonnegativeCount(value: unknown): value is number {
  return typeof value === "number" && Number.isSafeInteger(value) && value >= 0;
}

function isTimestamp(value: unknown): value is string {
  return (
    typeof value === "string" &&
    value.trim().length > 0 &&
    Number.isFinite(Date.parse(value))
  );
}

function validateMetrics(value: unknown): value is DashboardMetrics {
  return (
    isRecord(value) &&
    isNonnegativeCount(value.warningsToday) &&
    isNonnegativeCount(value.ticketsToday) &&
    isNonnegativeCount(value.openTickets) &&
    isNonnegativeCount(value.activeBusinesses)
  );
}

function isActivity(value: unknown): value is DashboardActivity {
  return (
    isRecord(value) &&
    typeof value.id === "number" &&
    Number.isSafeInteger(value.id) &&
    value.id > 0 &&
    isTimestamp(value.occurredAt) &&
    typeof value.category === "string" &&
    value.category.trim().length > 0 &&
    typeof value.title === "string" &&
    value.title.trim().length > 0 &&
    typeof value.description === "string" &&
    (value.actorName === null || typeof value.actorName === "string")
  );
}

function isRecordId(value: unknown): value is number {
  return typeof value === "number" && Number.isSafeInteger(value) && value > 0;
}

function isOverdueTicket(value: unknown): value is DashboardOverdueTicket {
  return (
    isRecord(value) &&
    isRecordId(value.id) &&
    (value.controlNumber === null || typeof value.controlNumber === "string") &&
    (value.vendorId === null || isRecordId(value.vendorId)) &&
    (value.businessName === null || typeof value.businessName === "string") &&
    isNonnegativeCount(value.daysOverdue)
  );
}

function validateOverdueTickets(
  value: unknown,
): value is DashboardOverdueTickets {
  return (
    isRecord(value) &&
    isNonnegativeCount(value.total) &&
    Array.isArray(value.items) &&
    value.items.length <= OVERDUE_TICKET_LIMIT &&
    value.items.length <= value.total &&
    value.items.every(isOverdueTicket)
  );
}

export function validateDashboardSummary(
  value: unknown,
): asserts value is DashboardSummary {
  if (
    !isRecord(value) ||
    !isTimestamp(value.asOf) ||
    !validateMetrics(value.metrics) ||
    !Array.isArray(value.recentActivity) ||
    value.recentActivity.length > 5 ||
    !value.recentActivity.every(isActivity) ||
    !validateOverdueTickets(value.overdueTickets)
  ) {
    throw new ApiRequestError();
  }
}
