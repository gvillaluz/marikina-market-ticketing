import { useCallback, useState } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { backupsApi } from "@/api/endpoints/backups.api";
import {
  backupError,
  backupKeys,
  formatBackupDate,
  formatBackupSize,
} from "../backups.utils";

export function useBackupHistory(canManage: boolean, timeZone?: string) {
  const client = useQueryClient();
  const [offsets, setOffsets] = useState([0]);
  const offset = offsets[offsets.length - 1];
  const query = useQuery({
    queryKey: [...backupKeys.history, offset],
    queryFn: ({ signal }) => backupsApi.getHistory(offset, signal),
    enabled: canManage,
  });
  const reset = useCallback(() => {
    setOffsets([0]);
    void client.invalidateQueries({ queryKey: backupKeys.history });
  }, [client]);
  const items = query.data?.items ?? [];
  return {
    rows: items.map((item) => ({
      ...item,
      dateLabel: formatBackupDate(item.dateTime, timeZone),
      sizeLabel: formatBackupSize(item.size),
    })),
    isLoading: query.isPending,
    isFetching: query.isFetching,
    isError: query.isError,
    error: backupError(
      query.error,
      "Unable to load backup history. Please try again.",
    ),
    total: query.data?.total,
    offset,
    hasData: query.data !== undefined,
    canPrevious: offsets.length > 1 && !query.isFetching,
    canNext: Boolean(
      query.data?.hasMore && items.length > 0 && !query.isFetching,
    ),
    hasPagination: offsets.length > 1 || Boolean(query.data?.hasMore),
    reset,
    retry() {
      void query.refetch();
    },
    previous() {
      if (offsets.length > 1 && !query.isFetching)
        setOffsets((current) => current.slice(0, -1));
    },
    next() {
      if (query.data?.hasMore && items.length > 0 && !query.isFetching)
        setOffsets((current) => [...current, offset + items.length]);
    },
  };
}

export type BackupHistoryModel = ReturnType<typeof useBackupHistory>;
export type BackupHistoryRowModel = BackupHistoryModel["rows"][number];
