import { useRef, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { backupsApi } from "@/api/endpoints/backups.api";
import type { BackupRestoreResponse } from "@/api/types/backups.types";
import { useAuth } from "@/context/AuthContext";
import { ApiRequestError } from "@/utils/apiErrors";
import {
  backupError,
  backupKeys,
  canConfirmRestore,
  getRestoreView,
  restoreConfirmHint,
} from "../backups.utils";
import type { BackupHistoryRowModel } from "./useBackupHistory";

interface RestoreTarget {
  id: number;
  dateLabel: string;
}

interface StartedRestore extends RestoreTarget {
  first: BackupRestoreResponse;
}

const PROGRESS_INTERVAL = 1000;

const isLost = (error: unknown) =>
  error instanceof ApiRequestError && error.status === 404;

// The restore of one backup: the confirm window's fields, starting it, and following its progress.
export function useBackupRestore() {
  const client = useQueryClient();
  const { logout } = useAuth();
  const [target, setTarget] = useState<RestoreTarget | null>(null);
  const [confirmation, setConfirmation] = useState("");
  const [password, setPassword] = useState("");
  const [passwordVisible, setPasswordVisible] = useState(false);
  const [started, setStarted] = useState<StartedRestore | null>(null);
  const starting = useRef(false);

  const startRestore = useMutation({
    mutationFn: (backup: RestoreTarget) =>
      backupsApi.startRestore(backup.id, { confirmation, password }),
    retry: false,
    onSuccess: (response, backup) => {
      setStarted({ ...backup, first: response });
      closeWindow();
    },
    onSettled: () => {
      starting.current = false;
    },
  });

  const progress = useQuery({
    queryKey: [...backupKeys.restore, started?.first.restoreId],
    queryFn: ({ signal }) =>
      backupsApi.getRestoreProgress(started!.first.restoreId, signal),
    enabled: started !== null,
    retry: false,
    staleTime: 0,
    refetchInterval: (query) =>
      isLost(query.state.error) ||
      query.state.data?.state === "Finished" ||
      query.state.data?.state === "Failed"
        ? false
        : PROGRESS_INTERVAL,
    refetchIntervalInBackground: true,
  });

  function closeWindow() {
    setTarget(null);
    setConfirmation("");
    setPassword("");
    setPasswordVisible(false);
  }

  const view = started
    ? getRestoreView(
        progress.data ?? started.first,
        started.dateLabel,
        isLost(progress.error)
          ? "lost"
          : progress.isError
            ? "unreachable"
            : "ok",
      )
    : null;

  return {
    target,
    confirmation,
    password,
    passwordVisible,
    hint: restoreConfirmHint(confirmation, password),
    canStart:
      canConfirmRestore(confirmation, password) && !startRestore.isPending,
    isStarting: startRestore.isPending,
    startError: startRestore.isError
      ? backupError(
          startRestore.error,
          "The restore could not be started. Please try again.",
        )
      : "",
    // While a restore is followed, the Backups page shows only the restore view.
    isActive: started !== null,
    view,
    open(backup: BackupHistoryRowModel) {
      if (backup.restoreDisabled || started) return;
      startRestore.reset();
      setTarget({ id: backup.id, dateLabel: backup.dateLabel });
    },
    cancel() {
      if (startRestore.isPending) return;
      startRestore.reset();
      closeWindow();
    },
    setConfirmation,
    setPassword,
    togglePassword() {
      setPasswordVisible((visible) => !visible);
    },
    start() {
      if (
        !target ||
        !canConfirmRestore(confirmation, password) ||
        startRestore.isPending ||
        starting.current
      )
        return;
      starting.current = true;
      startRestore.mutate(target);
    },
    back() {
      setStarted(null);
      void client.invalidateQueries({ queryKey: ["backups"] });
    },
    signInAgain: logout,
  };
}

export type BackupRestoreModel = ReturnType<typeof useBackupRestore>;
