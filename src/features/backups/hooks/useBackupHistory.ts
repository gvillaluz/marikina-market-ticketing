import { useCallback, useRef, useState } from "react";
import {
  keepPreviousData,
  useMutation,
  useQuery,
  useQueryClient,
} from "@tanstack/react-query";
import { backupsApi } from "@/api/endpoints/backups.api";
import type { BackupResponse } from "@/api/types/backups.types";
import { ApiRequestError } from "@/utils/apiErrors";
import {
  backupError,
  backupKeys,
  formatBackupDate,
  formatBackupSize,
} from "../backups.utils";

const PAGE_SIZE = 10;

export function useBackupHistory(canManage: boolean, timeZone?: string) {
  const client = useQueryClient();
  const [page, setPage] = useState(1);
  const downloading = useRef(false);
  const offset = (page - 1) * PAGE_SIZE;
  const query = useQuery({
    queryKey: [...backupKeys.history, offset],
    queryFn: async ({ signal }) => {
      if (!Number.isSafeInteger(offset) || offset < 0)
        throw new ApiRequestError();
      const response = await backupsApi.getHistory(offset, signal);
      if (
        !response ||
        !Array.isArray(response.items) ||
        typeof response.hasMore !== "boolean" ||
        (response.total != null &&
          (!Number.isSafeInteger(response.total) || response.total < 0))
      )
        throw new ApiRequestError();
      return response;
    },
    enabled: canManage,
    placeholderData: keepPreviousData,
  });
  const reset = useCallback(() => {
    setPage(1);
    void client.invalidateQueries({ queryKey: backupKeys.history });
  }, [client]);
  const download = useMutation({
    mutationFn: (backup: BackupResponse) => backupsApi.download(backup.id),
    retry: false,
    onSuccess: (result) => {
      const url = URL.createObjectURL(result.blob);
      const link = document.createElement("a");
      link.href = url;
      link.download = result.fileName;
      document.body.appendChild(link);
      try {
        link.click();
      } finally {
        link.remove();
        window.setTimeout(() => URL.revokeObjectURL(url), 1000);
      }
    },
    onSettled: () => {
      downloading.current = false;
    },
  });
  const items = query.data?.items ?? [];
  const hasMore = query.data?.hasMore ?? false;
  const total = query.data?.total;
  const totalPages = Math.max(
    page + (hasMore ? 1 : 0),
    total == null ? 1 : Math.ceil(total / PAGE_SIZE),
  );
  function canDownload(backup: BackupResponse) {
    return (
      canManage &&
      backup.canDownload &&
      backup.status === "Completed" &&
      Number.isSafeInteger(backup.id) &&
      backup.id > 0 &&
      backup.downloadRoute === `/api/admin/backups/${backup.id}/download`
    );
  }
  return {
    rows: items.map((item) => ({
      ...item,
      dateLabel: formatBackupDate(item.dateTime, timeZone),
      sizeLabel: formatBackupSize(item.size),
      downloadDisabled: !canDownload(item) || download.isPending,
      isDownloading: download.isPending && download.variables?.id === item.id,
    })),
    isLoading: query.isPending || query.isPlaceholderData,
    isFetching: query.isFetching,
    isError: query.isError,
    error: backupError(
      query.error,
      "Unable to load backup history. Please try again.",
    ),
    total,
    offset,
    page,
    totalPages,
    rangeLabel: query.isPlaceholderData
      ? "Loading backup history…"
      : `Showing ${items.length ? offset + 1 : 0}–${items.length ? offset + items.length : 0}${total != null ? ` of ${total}` : ""} backups`,
    hasData: query.data !== undefined,
    canNext: hasMore && items.length > 0 && !query.isFetching && !query.isError,
    downloadError: download.isError
      ? backupError(
          download.error,
          "Unable to download this backup. Please try again.",
        )
      : "",
    reset,
    retry() {
      void query.refetch();
    },
    changePage(nextPage: number) {
      if (
        !canManage ||
        query.isFetching ||
        !Number.isSafeInteger(nextPage) ||
        nextPage < 1 ||
        nextPage > totalPages ||
        (nextPage > page && (!hasMore || query.isError))
      )
        return;
      setPage(nextPage);
    },
    download(backup: BackupResponse) {
      if (!canDownload(backup) || download.isPending || downloading.current)
        return;
      downloading.current = true;
      download.mutate(backup);
    },
  };
}

export type BackupHistoryModel = ReturnType<typeof useBackupHistory>;
export type BackupHistoryRowModel = BackupHistoryModel["rows"][number];
