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
  checkRestoreFile,
  getRestoreView,
  restoreConfirmHint,
  restoreWindowText,
  type RestoreTarget,
} from "../backups.utils";
import type { BackupHistoryRowModel } from "./useBackupHistory";

interface StartRequest {
  target: RestoreTarget;
  file: File | null;
}

interface StartedRestore {
  sourceLabel: string;
  first: BackupRestoreResponse;
}

const PROGRESS_INTERVAL = 1000;

const isLost = (error: unknown) =>
  error instanceof ApiRequestError && error.status === 404;

// The restore of one backup, from the list or from a file: the confirm window's fields,
// starting it, and following its progress.
export function useBackupRestore() {
  const client = useQueryClient();
  const { logout } = useAuth();
  const [target, setTarget] = useState<RestoreTarget | null>(null);
  const [file, setFile] = useState<File | null>(null);
  const [uploadPercent, setUploadPercent] = useState<number | null>(null);
  const [confirmation, setConfirmation] = useState("");
  const [password, setPassword] = useState("");
  const [passwordVisible, setPasswordVisible] = useState(false);
  const [started, setStarted] = useState<StartedRestore | null>(null);
  const starting = useRef(false);

  const startRestore = useMutation({
    mutationFn: (start: StartRequest) =>
      start.target.kind === "backup"
        ? backupsApi.startRestore(start.target.id, { confirmation, password })
        : backupsApi.startUploadRestore(
            start.file!,
            { confirmation, password },
            setUploadPercent,
          ),
    retry: false,
    onMutate: (start) => {
      if (start.target.kind === "file") setUploadPercent(0);
    },
    onSuccess: (response, start) => {
      setStarted({
        sourceLabel: restoreWindowText(start.target, start.file).source,
        first: response,
      });
      closeWindow();
    },
    onSettled: () => {
      starting.current = false;
      setUploadPercent(null);
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

  const fileError = checkRestoreFile(file);
  const fileReady = target?.kind !== "file" || (file !== null && !fileError);

  function closeWindow() {
    setTarget(null);
    setFile(null);
    setConfirmation("");
    setPassword("");
    setPasswordVisible(false);
  }

  const view = started
    ? getRestoreView(
        progress.data ?? started.first,
        started.sourceLabel,
        isLost(progress.error)
          ? "lost"
          : progress.isError
            ? "unreachable"
            : "ok",
      )
    : null;

  return {
    target,
    // A file is named in the window only once it passes the checks.
    windowText: target
      ? restoreWindowText(target, fileError ? null : file)
      : null,
    fileError,
    uploadPercent,
    confirmation,
    password,
    passwordVisible,
    hint: restoreConfirmHint(
      confirmation,
      password,
      target?.kind === "file" && file === null,
    ),
    canStart:
      canConfirmRestore(confirmation, password) &&
      fileReady &&
      !startRestore.isPending,
    isStarting: startRestore.isPending,
    startError: startRestore.isError
      ? backupError(
          startRestore.error,
          target?.kind === "file"
            ? "The file could not be sent. Check the connection and try again."
            : "The restore could not be started. Please try again.",
        )
      : "",
    // While a restore is followed, the Backups page shows only the restore view.
    isActive: started !== null,
    view,
    open(backup: BackupHistoryRowModel) {
      if (backup.restoreDisabled || started) return;
      startRestore.reset();
      setTarget({ kind: "backup", id: backup.id, dateLabel: backup.dateLabel });
    },
    openFile() {
      if (started) return;
      startRestore.reset();
      setFile(null);
      setTarget({ kind: "file" });
    },
    setFile(chosen: File | null) {
      startRestore.reset();
      setFile(chosen);
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
        !fileReady ||
        startRestore.isPending ||
        starting.current
      )
        return;
      starting.current = true;
      startRestore.mutate({ target, file });
    },
    back() {
      setStarted(null);
      void client.invalidateQueries({ queryKey: ["backups"] });
    },
    signInAgain: logout,
  };
}

export type BackupRestoreModel = ReturnType<typeof useBackupRestore>;
