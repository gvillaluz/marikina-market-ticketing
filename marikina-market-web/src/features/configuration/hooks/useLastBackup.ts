import { useQuery } from "@tanstack/react-query";
import { backupsApi } from "@/api/endpoints/backups.api";
import { useAuthStore } from "@/store/store";
import { backupError, backupKeys, formatBackupDate } from "@/features/backups";

export function useLastBackup() {
  const canView = useAuthStore((state) => state.user?.role === "HeadAdmin");
  const query = useQuery({
    queryKey: backupKeys.health,
    queryFn: ({ signal }) => backupsApi.getHealth(signal),
    enabled: canView,
  });
  const latest = query.data?.latestSuccessfulBackup;

  return {
    canView,
    isLoading: query.isPending,
    isFetching: query.isFetching,
    error: query.isError
      ? backupError(
          query.error,
          "Unable to load backup status. Please try again.",
        )
      : "",
    retry: () => {
      void query.refetch();
    },
    value: latest
      ? formatBackupDate(
          latest.completedAt || latest.dateTime,
          query.data?.timeZone,
        )
      : "None yet",
    note: latest ? "Last successful backup" : "No successful backup recorded",
  };
}
