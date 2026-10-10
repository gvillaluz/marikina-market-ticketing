import { USER_ROLES } from "@/api/types/common.types";
import type {
  AuditCounts,
  AuditLogDetail,
  AuditLogSummary,
  AuditPageResponse,
} from "@/api/types/audit.types";
import { ApiRequestError } from "@/utils/apiErrors";
import {
  AUDIT_MODULE_OPTIONS,
  AUDIT_PAGE_SIZE,
  AUDIT_RESULT_OPTIONS,
} from "./audit.constants";

function isAuditRecord(value: unknown): value is AuditLogSummary {
  if (!value || typeof value !== "object") return false;
  const record = value as Partial<AuditLogSummary>;
  return (
    Number.isSafeInteger(record.id) &&
    (record.id ?? 0) > 0 &&
    typeof record.timestamp === "string" &&
    Number.isFinite(Date.parse(record.timestamp)) &&
    (record.userId === null ||
      (Number.isSafeInteger(record.userId) && (record.userId ?? 0) > 0)) &&
    [record.firstName, record.lastName].every(
      (name) => name === null || typeof name === "string",
    ) &&
    (record.role === null || USER_ROLES.some((role) => role === record.role)) &&
    typeof record.action === "string" &&
    record.action.trim().length > 0 &&
    AUDIT_MODULE_OPTIONS.some((option) => option.value === record.module) &&
    AUDIT_RESULT_OPTIONS.some((option) => option.value === record.result)
  );
}

export function validateAuditPage(data: AuditPageResponse): AuditPageResponse {
  if (
    !data ||
    !Array.isArray(data.items) ||
    data.items.length > AUDIT_PAGE_SIZE ||
    !data.items.every(isAuditRecord) ||
    typeof data.hasMore !== "boolean" ||
    !Number.isSafeInteger(data.total) ||
    data.total < data.items.length ||
    (data.hasMore && data.items.length !== AUDIT_PAGE_SIZE)
  )
    throw new ApiRequestError();
  return data;
}

export function validateAuditCounts(data: AuditCounts): AuditCounts {
  if (
    !data ||
    ![
      data.recordedActivities,
      data.successfulActions,
      data.securityEvents,
    ].every((value) => Number.isSafeInteger(value) && value >= 0) ||
    data.successfulActions > data.recordedActivities ||
    data.securityEvents > data.recordedActivities
  )
    throw new ApiRequestError();
  return data;
}

export function validateAuditDetail(
  data: AuditLogDetail,
  id: number,
): AuditLogDetail {
  if (
    !isAuditRecord(data) ||
    data.id !== id ||
    !(data.targetId === null || typeof data.targetId === "string") ||
    !(data.details === null || typeof data.details === "string")
  )
    throw new ApiRequestError();
  return data;
}
