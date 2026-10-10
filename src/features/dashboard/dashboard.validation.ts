import type {
  DashboardActivity,
  DashboardAttentionItem,
  DashboardMetrics,
  DashboardSummary,
} from "@/api/types/dashboard.types";
import { ApiRequestError } from "@/utils/apiErrors";

const ATTENTION_TYPES = ["OpenTickets", "PendingRegistrations"] as const;

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
    isNonnegativeCount(value.inspectionsToday) &&
    isNonnegativeCount(value.openTickets) &&
    isNonnegativeCount(value.activeVendors) &&
    isNonnegativeCount(value.pendingRegistrations)
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

function isAttentionItem(value: unknown): value is DashboardAttentionItem {
  return (
    isRecord(value) &&
    typeof value.id === "string" &&
    value.id.trim().length > 0 &&
    typeof value.type === "string" &&
    ATTENTION_TYPES.includes(value.type as (typeof ATTENTION_TYPES)[number]) &&
    typeof value.title === "string" &&
    value.title.trim().length > 0 &&
    typeof value.count === "number" &&
    Number.isSafeInteger(value.count) &&
    value.count > 0
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
    !Array.isArray(value.attentionItems) ||
    !value.attentionItems.every(isAttentionItem)
  ) {
    throw new ApiRequestError();
  }
}
