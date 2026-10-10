import type { AuditFilters } from "../types/audit.types";

export function auditQuery(filters: AuditFilters, offset?: number): string {
  const query = new URLSearchParams();
  if (offset !== undefined) {
    if (!Number.isSafeInteger(offset) || offset < 0 || offset % 10 !== 0)
      throw new RangeError("Invalid audit page offset.");
    query.set("offset", String(offset));
  }
  for (const module of [...new Set(filters.modules ?? [])].sort())
    query.append("modules", module);
  for (const result of [...new Set(filters.results ?? [])].sort())
    query.append("results", result);
  if (filters.dateRange && filters.dateRange !== "AllTime")
    query.set("dateRange", filters.dateRange);
  if (filters.search?.trim()) query.set("search", filters.search.trim());
  if (filters.userId !== undefined) {
    if (!Number.isSafeInteger(filters.userId) || filters.userId <= 0)
      throw new RangeError("Invalid audit user ID.");
    query.set("userId", String(filters.userId));
  }
  if (filters.role) query.set("role", filters.role);
  const value = query.toString();
  return value ? `?${value}` : "";
}
