import { useState } from "react";
import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { accountsApi } from "@/api/endpoints/accounts.api";
import type { UserRole } from "@/api/types/common.types";
import useDebounce from "@/hooks/useDebounce";
import { ApiRequestError, getApiErrorMessage } from "@/utils/apiErrors";
import { ACCOUNT_TABS } from "../accounts.constants";

const PAGE_SIZE = 10;

export function useAccounts() {
  const [search, setSearch] = useState("");
  const [role, setRole] = useState<UserRole | "all">("all");
  const [page, setPage] = useState(1);
  const debouncedSearch = useDebounce(search.trim(), 350);
  const offset = (page - 1) * PAGE_SIZE;
  const counts = useQuery({
    queryKey: ["account-counts"],
    queryFn: async ({ signal }) => {
      const data = await accountsApi.getCounts(signal);
      if (
        !data ||
        ![
          data.totalStaffUsers,
          data.totalMarketVendorUsers,
          data.totalAdministrators,
          data.totalActiveAccounts,
        ].every((value) => Number.isSafeInteger(value) && value >= 0)
      )
        throw new ApiRequestError();
      return data;
    },
  });
  const directory = useQuery({
    queryKey: ["accounts", offset, role, debouncedSearch],
    placeholderData: keepPreviousData,
    queryFn: async ({ signal }) => {
      const data = await accountsApi.list(
        {
          offset,
          role: role === "all" ? undefined : role,
          search: debouncedSearch || undefined,
        },
        signal,
      );
      if (
        !data ||
        !Array.isArray(data.items) ||
        !data.items.every(
          (account) =>
            account &&
            Number.isSafeInteger(account.id) &&
            account.id > 0 &&
            ACCOUNT_TABS.some(
              (tab) => tab.role !== "all" && tab.role === account.role,
            ) &&
            [
              account.role,
              account.username,
              account.firstName,
              account.lastName,
            ].every((value) => typeof value === "string") &&
            [
              account.middleName,
              account.email,
              account.phoneNumber,
              account.profileUrl,
            ].every((value) => value === null || typeof value === "string") &&
            (account.status === "Active" || account.status === "Inactive"),
        ) ||
        typeof data.hasMore !== "boolean" ||
        !Number.isSafeInteger(data.total) ||
        data.total < 0
      )
        throw new ApiRequestError();
      return data;
    },
  });
  const items = directory.data?.items ?? [];
  const total = directory.data?.total ?? 0;
  const waitingForSearch = search.trim() !== debouncedSearch;
  const isLoading =
    directory.isPending || directory.isPlaceholderData || waitingForSearch;
  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));
  return {
    counts: counts.data,
    countsLoading: counts.isPending,
    countsError: counts.isError
      ? getApiErrorMessage(
          counts.error,
          "Unable to load account counts. Please try again.",
        )
      : "",
    retryCounts: () => {
      void counts.refetch();
    },
    items,
    search,
    role,
    page,
    totalPages,
    isLoading,
    isFetching: directory.isFetching || waitingForSearch,
    error: directory.isError
      ? getApiErrorMessage(
          directory.error,
          "Unable to load accounts. Please try again.",
        )
      : "",
    rangeLabel: isLoading
      ? "Loading accounts…"
      : `Showing ${items.length ? offset + 1 : 0}–${items.length ? offset + items.length : 0} of ${total} system accounts`,
    canNext:
      Boolean(directory.data?.hasMore) &&
      items.length > 0 &&
      !directory.isFetching &&
      !directory.isError &&
      !waitingForSearch,
    retry: () => {
      void directory.refetch();
    },
    changeSearch(value: string) {
      setSearch(value.slice(0, 200).replace(/[\u0000-\u001f\u007f]/g, ""));
      setPage(1);
    },
    changeRole(value: UserRole | "all") {
      if (!ACCOUNT_TABS.some((tab) => tab.role === value)) return;
      setRole(value);
      setPage(1);
    },
    changePage(value: number) {
      if (
        directory.isFetching ||
        waitingForSearch ||
        !Number.isSafeInteger(value) ||
        value < 1 ||
        value > totalPages ||
        (value > page && (!directory.data?.hasMore || directory.isError))
      )
        return;
      setPage(value);
    },
  };
}

export type AccountsModel = ReturnType<typeof useAccounts>;
