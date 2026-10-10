import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { useAuth } from "@/context/AuthContext";
import { auditApi } from "@/api/endpoints/audit.api";
import type {
  AuditDateRange,
  AuditFilters,
  AuditLogSummary,
  AuditModule,
  AuditResult,
} from "@/api/types/audit.types";
import useDebounce from "@/hooks/useDebounce";
import { isAdministrator } from "@/utils/roles";
import { ApiRequestError, getApiErrorMessage } from "@/utils/apiErrors";
import {
  AUDIT_DATE_OPTIONS,
  AUDIT_MODULE_OPTIONS,
  AUDIT_PAGE_SIZE,
  AUDIT_RESULT_OPTIONS,
} from "../audit.constants";
import { validateAuditCounts, validateAuditPage } from "../audit.validation";
import { useAuditDetails } from "./useAuditDetails";
import { useAuditExport } from "./useAuditExport";

export function useAuditLogs() {
  const [search, setSearch] = useState("");
  const [modules, setModules] = useState<AuditModule[]>([]);
  const [results, setResults] = useState<AuditResult[]>([]);
  const [dateRange, setDateRange] = useState<AuditDateRange>("AllTime");
  const [page, setPage] = useState(1);
  const [selected, setSelected] = useState<AuditLogSummary | null>(null);
  const debouncedSearch = useDebounce(search.trim(), 350);
  const { user } = useAuth();
  const canReview = isAdministrator(user?.role);
  const isDebouncing = search.trim() !== debouncedSearch;
  const offset = (page - 1) * AUDIT_PAGE_SIZE;
  const filters: AuditFilters = {
    modules,
    results,
    dateRange,
    search: debouncedSearch || undefined,
  };
  const directory = useQuery({
    queryKey: ["audit", user?.userId, "list", filters, offset],
    enabled: canReview && !isDebouncing,
    gcTime: 0,
    retry: false,
    queryFn: async ({ signal }) =>
      validateAuditPage(await auditApi.list(filters, offset, signal)),
  });
  const counts = useQuery({
    queryKey: ["audit", user?.userId, "counts", filters],
    enabled: canReview && !isDebouncing,
    gcTime: 0,
    retry: false,
    queryFn: async ({ signal }) =>
      validateAuditCounts(await auditApi.counts(filters, signal)),
  });
  const detail = useAuditDetails(selected?.id ?? null);
  const exporter = useAuditExport();
  const isLoading = directory.isPending || isDebouncing;
  const isFetching = directory.isFetching || isDebouncing;
  const items =
    directory.isError || isDebouncing ? [] : (directory.data?.items ?? []);
  const total = directory.data?.total ?? 0;
  const totalPages = Math.max(page, Math.ceil(total / AUDIT_PAGE_SIZE), 1);
  const hasFilters =
    Boolean(search.trim()) ||
    modules.length > 0 ||
    results.length > 0 ||
    dateRange !== "AllTime";
  const canNext =
    Boolean(directory.data?.hasMore) && !isFetching && !directory.isError;
  const error = directory.isError
    ? getApiErrorMessage(
        directory.error instanceof ApiRequestError
          ? directory.error
          : undefined,
        "Unable to load audit logs. Please try again.",
      )
    : "";

  return {
    search,
    modules,
    results,
    dateRange,
    items,
    selected,
    isLoading,
    isFetching,
    hasFilters,
    page,
    total,
    totalPages,
    canNext,
    error,
    isFiltering: isLoading,
    counts: counts.isError ? undefined : counts.data,
    countsLoading: counts.isPending || counts.isFetching || isDebouncing,
    countsError: counts.isError
      ? getApiErrorMessage(
          counts.error instanceof ApiRequestError ? counts.error : undefined,
          "Unable to load audit counts. Please try again.",
        )
      : "",
    isExporting: exporter.isExporting,
    canExport:
      canReview &&
      directory.isSuccess &&
      total > 0 &&
      !isFetching &&
      !exporter.isExporting,
    detail: {
      ...detail,
      selectedId: selected?.id ?? null,
      close: () => setSelected(null),
    },
    rangeLabel: error
      ? "Activity history unavailable"
      : isLoading
        ? "Loading activities…"
        : `Showing ${items.length ? offset + 1 : 0}–${items.length ? offset + items.length : 0} of ${total} activities`,
    changeSearch(value: string) {
      if (exporter.isExporting) return;
      setSearch(value.slice(0, 200).replace(/[\u0000-\u001f\u007f]/g, ""));
      setPage(1);
    },
    toggleModule(value: string) {
      if (
        exporter.isExporting ||
        !AUDIT_MODULE_OPTIONS.some((option) => option.value === value)
      )
        return;
      const module = value as AuditModule;
      setModules((current) =>
        current.includes(module)
          ? current.filter((item) => item !== module)
          : [...current, module].sort(),
      );
      setPage(1);
    },
    toggleResult(value: string) {
      if (
        exporter.isExporting ||
        !AUDIT_RESULT_OPTIONS.some((option) => option.value === value)
      )
        return;
      const result = value as AuditResult;
      setResults((current) =>
        current.includes(result)
          ? current.filter((item) => item !== result)
          : [...current, result].sort(),
      );
      setPage(1);
    },
    clearModules() {
      if (!exporter.isExporting) {
        setModules([]);
        setPage(1);
      }
    },
    clearResults() {
      if (!exporter.isExporting) {
        setResults([]);
        setPage(1);
      }
    },
    changeDateRange(value: string) {
      if (
        exporter.isExporting ||
        !AUDIT_DATE_OPTIONS.some((option) => option.value === value)
      )
        return;
      setDateRange(value as AuditDateRange);
      setPage(1);
    },
    changePage(value: number) {
      if (
        isFetching ||
        exporter.isExporting ||
        !Number.isSafeInteger(value) ||
        value < 1 ||
        value > totalPages ||
        (value > page && !canNext)
      )
        return;
      setPage(value);
      void counts.refetch();
    },
    resetFilters() {
      if (exporter.isExporting) return;
      setSearch("");
      setModules([]);
      setResults([]);
      setDateRange("AllTime");
      setPage(1);
    },
    retry: () => {
      void directory.refetch();
    },
    retryCounts: () => {
      void counts.refetch();
    },
    view(record: AuditLogSummary) {
      if (canReview) setSelected(record);
    },
    exportLogs: () => {
      if (canReview && directory.isSuccess && total > 0 && !isFetching)
        void exporter.exportLogs(filters);
    },
  };
}

export type AuditLogsModel = ReturnType<typeof useAuditLogs>;
