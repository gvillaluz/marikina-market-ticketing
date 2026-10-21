import client from "@/api/client";
import { ApiRequestError } from "@/utils/apiErrors";
import type {
  AuditCounts,
  AuditFilters,
  AuditLogDetail,
  AuditPageResponse,
} from "../types/audit.types";
import { auditQuery } from "./audit.query";

const path = "/admin/audit-logs";

export const auditApi = {
  async list(
    filters: AuditFilters,
    offset: number,
    signal?: AbortSignal,
  ): Promise<AuditPageResponse> {
    // A URL query preserves camelCase keys and repeated arrays through the shared snake_case interceptor.
    const { data } = await client.get<AuditPageResponse>(
      `${path}${auditQuery(filters, offset)}`,
      { signal },
    );
    return data;
  },
  async counts(
    filters: AuditFilters,
    signal?: AbortSignal,
  ): Promise<AuditCounts> {
    const { data } = await client.get<AuditCounts>(
      `${path}/counts${auditQuery(filters)}`,
      { signal },
    );
    return data;
  },
  async details(id: number, signal?: AbortSignal): Promise<AuditLogDetail> {
    if (!Number.isSafeInteger(id) || id <= 0) throw new ApiRequestError();
    const { data } = await client.get<AuditLogDetail>(`${path}/${id}`, {
      signal,
    });
    return data;
  },
};
