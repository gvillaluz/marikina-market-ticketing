import { useEffect, useRef } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useAuthStore } from "@/store/store";
import { backupsApi } from "@/api/endpoints/backups.api";
import {
  backupError,
  backupKeys,
  formatBackupDate,
  formatBackupSize,
  getBackupHealthView,
} from "../backups.utils";
import { useBackupSchedule } from "./useBackupSchedule";
import { useBackupHistory } from "./useBackupHistory";

export function useBackups() {
  const client = useQueryClient();
  const canManage = useAuthStore((state) => state.user?.role === "Admin");
  const schedule = useBackupSchedule(canManage);
  const health = useQuery({
    queryKey: backupKeys.health,
    queryFn: ({ signal }) => backupsApi.getHealth(signal),
    enabled: canManage,
    refetchInterval: (query) => (query.state.data?.isRunning ? 5000 : 30000),
    refetchIntervalInBackground: false,
    refetchOnWindowFocus: true,
  });
  const history = useBackupHistory(canManage, health.data?.timeZone);
  const wasRunning = useRef(false);
  const previousAttempt = useRef<string | null>(null);
  const hasHealthSample = useRef(false);
  const submitting = useRef(false);
  const resetHistory = history.reset;
  useEffect(() => {
    if (!health.data) return;
    const latest = health.data.latestAttempt;
    const attempt = latest
      ? `${latest.id}:${latest.status}:${latest.completedAt}`
      : null;
    if (
      (wasRunning.current && !health.data.isRunning) ||
      (hasHealthSample.current && previousAttempt.current !== attempt)
    )
      resetHistory();
    wasRunning.current = health.data.isRunning;
    previousAttempt.current = attempt;
    hasHealthSample.current = true;
  }, [health.data, resetHistory]);
  const manual = useMutation({
    mutationFn: backupsApi.createManual,
    retry: false,
    onSuccess: () => {
      resetHistory();
      void client.invalidateQueries({ queryKey: backupKeys.health });
    },
    onError: () => {
      // A timeout can occur after the server has started a backup.
      resetHistory();
      void client.invalidateQueries({ queryKey: backupKeys.health });
    },
    onSettled: () => {
      submitting.current = false;
    },
  });
  const latest = health.data?.latestSuccessfulBackup;
  return {
    schedule,
    history,
    health: {
      view: health.data ? getBackupHealthView(health.data) : null,
      isLoading: health.isPending,
      isFetching: health.isFetching,
      isError: health.isError,
      error: backupError(
        health.error,
        "Unable to load backup health. Please try again.",
      ),
      sizeLabel: formatBackupSize(latest?.size),
      retentionLabel: health.data ? `${health.data.retentionDays} days` : "—",
      lastSuccessfulLabel: latest
        ? formatBackupDate(
            latest.completedAt || latest.dateTime,
            health.data?.timeZone,
          )
        : null,
      retry() {
        void health.refetch();
      },
    },
    manualError: manual.isError
      ? backupError(
          manual.error,
          "Unable to confirm the backup result. Refresh health and history before trying again.",
        )
      : "",
    manualSuccess: manual.isSuccess
      ? manual.data.status === "Failed"
        ? manual.data.errorMessage || "The backup failed. Please try again."
        : "Backup completed successfully."
      : "",
    manualFailed: manual.isSuccess && manual.data.status === "Failed",
    isBackingUp: manual.isPending || Boolean(health.data?.isRunning),
    canBackup:
      canManage &&
      health.isSuccess &&
      !health.data.isRunning &&
      !manual.isPending,
    backupNow() {
      if (
        !canManage ||
        !health.isSuccess ||
        health.data.isRunning ||
        manual.isPending ||
        submitting.current
      )
        return;
      submitting.current = true;
      manual.mutate();
    },
  };
}

export type BackupHealthModel = ReturnType<typeof useBackups>["health"];
