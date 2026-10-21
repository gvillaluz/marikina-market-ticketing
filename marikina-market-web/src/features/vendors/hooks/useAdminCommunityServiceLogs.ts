import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { adminVendorsApi } from "@/api/endpoints/adminVendors.api";
import type { AdminCommunityServiceLog } from "@/api/types/admin-vendor.types";
import type { RecordStatus } from "@/api/types/common.types";
import { getApiErrorMessage } from "@/utils/apiErrors";

const PAGE_SIZE = 10;

export type CommunityServiceStatusFilter =
  | "all"
  | RecordStatus;

export function useAdminCommunityServiceLogs() {
  const [status, setStatusValue] =
    useState<CommunityServiceStatusFilter>("all");
  const [page, setPage] = useState(1);
  const offset = (page - 1) * PAGE_SIZE;

  const query = useQuery({
    queryKey: ["admin-community-service-logs", offset, status],
    queryFn: () =>
      adminVendorsApi.getCommunityServiceLogs({
        offset,
        status: status === "all" ? undefined : status,
      }),
  });

  function setStatus(nextStatus: CommunityServiceStatusFilter) {
    setStatusValue(nextStatus);
    setPage(1);
  }

  const logs = query.data?.items ?? [];
  const total = query.data?.total ?? null;
  const hasMore = query.data?.hasMore ?? false;
  const totalLabel =
    total ?? `${offset + logs.length}${hasMore ? "+" : ""}`;
  const totalPages = Math.max(
    1,
    total == null ? 1 : Math.ceil(total / PAGE_SIZE),
    page + (hasMore ? 1 : 0),
  );

  function getProgressStatus(log: AdminCommunityServiceLog) {
    if (log.completedHours <= 0) return "pending";
    if (log.totalHours > 0 && log.completedHours >= log.totalHours) {
      return "completed";
    }
    if (String(log.status).toLowerCase() === "overdue") return "overdue";
    return "inProgress";
  }

  return {
    logs,
    page,
    setPage,
    status,
    setStatus,
    totalLabel,
    offset,
    totalPages,
    hasMore,
    isLoading: query.isLoading,
    isError: query.isError,
    errorMessage: getApiErrorMessage(query.error, "Unable to load community service logs."),
    refetch: query.refetch,
    getProgressStatus,
  };
}
