import { useDeferredValue, useState } from "react";
import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { reportsApi } from "@/api/endpoints/reports.api";
import type { ReportType } from "@/api/types/reports.types";
import { ApiRequestError } from "@/utils/apiErrors";
import { filterReports, REPORT_PAGE_SIZE } from "../reports.utils";

export function useReportHistory() {
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState("");
  const [type, setType] = useState<ReportType | "all">("all");
  const deferredSearch = useDeferredValue(search);
  const filtered = Boolean(deferredSearch.trim()) || type !== "all";
  const query = useQuery({
    retry: false,
    staleTime: 0,
    queryKey: ["reports", "history", filtered ? "all" : page],
    queryFn: async ({ signal }) =>
      filtered
        ? { items: await reportsApi.listAll(signal), total: 0, hasMore: false }
        : reportsApi.list((page - 1) * REPORT_PAGE_SIZE, signal),
    placeholderData: keepPreviousData,
  });
  const matches = filtered
    ? filterReports(query.data?.items ?? [], deferredSearch, type)
    : (query.data?.items ?? []);
  const total = filtered ? matches.length : (query.data?.total ?? 0);
  const totalPages = Math.max(1, Math.ceil(total / REPORT_PAGE_SIZE));
  const currentPage = Math.min(page, totalPages);
  const rows = filtered
    ? matches.slice(
        (currentPage - 1) * REPORT_PAGE_SIZE,
        currentPage * REPORT_PAGE_SIZE,
      )
    : matches;
  const busy = query.isFetching || search !== deferredSearch;
  return {
    rows,
    total,
    totalPages,
    page: currentPage,
    pageSize: REPORT_PAGE_SIZE,
    search,
    type,
    busy,
    loading:
      query.isPending ||
      query.isPlaceholderData ||
      (query.isError && query.isFetching),
    error:
      query.isError && !query.isFetching
        ? query.error instanceof ApiRequestError && query.error.serverMessage
          ? query.error.serverMessage
          : "Unable to load report history. Please try again."
        : "",
    changeSearch(value: string) {
      setSearch(value.slice(0, 200));
      setPage(1);
    },
    changeType(value: ReportType | "all") {
      setType(value);
      setPage(1);
    },
    changePage(value: number) {
      if (
        !busy &&
        Number.isSafeInteger(value) &&
        value >= 1 &&
        value <= totalPages
      )
        setPage(value);
    },
    retry() {
      void query.refetch();
    },
  };
}
export type ReportHistoryModel = ReturnType<typeof useReportHistory>;
