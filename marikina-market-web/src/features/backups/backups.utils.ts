import { ApiRequestError } from "@/utils/apiErrors";
import type {
  BackupHealthResponse,
  BackupRestoreResponse,
  BackupType,
  RestoreStep,
  BackupScheduleResponse,
  BackupWeekday,
  UpdateBackupScheduleRequest,
} from "@/api/types/backups.types";

export const backupWeekdays: BackupWeekday[] = [
  "Sunday",
  "Monday",
  "Tuesday",
  "Wednesday",
  "Thursday",
  "Friday",
  "Saturday",
];

export function validateBackupScheduleResponse(
  response: BackupScheduleResponse,
): BackupScheduleResponse {
  if (!response || validateBackupSchedule(response))
    throw new ApiRequestError();
  return response;
}

export const backupKeys = {
  schedule: ["backups", "schedule"] as const,
  health: ["backups", "health"] as const,
  history: ["backups", "history"] as const,
  restore: ["backups", "restore"] as const,
};

export function backupError(error: unknown, fallback: string): string {
  return error instanceof ApiRequestError
    ? error.serverMessage || fallback
    : fallback;
}

export function backupTimeZone(value?: string): string {
  try {
    if (value) {
      new Intl.DateTimeFormat("en-US", { timeZone: value });
      return value;
    }
  } catch {
    /* Invalid API timezone: use the documented default. */
  }
  return "Asia/Manila";
}

export function formatBackupDate(
  value: string | null | undefined,
  timeZone?: string,
): string {
  if (!value) return "Unavailable";
  const date = new Date(value);
  if (!Number.isFinite(date.getTime())) return "Unavailable";
  return new Intl.DateTimeFormat("en-US", {
    timeZone: backupTimeZone(timeZone),
    month: "short",
    day: "numeric",
    year: "numeric",
    hour: "numeric",
    minute: "2-digit",
    hour12: true,
  }).format(date);
}

export function formatBackupSize(size: number | undefined): string {
  if (size === undefined || !Number.isFinite(size) || size < 0) return "—";
  if (size < 1024) return `${size} B`;
  if (size < 1024 ** 2) return `${(size / 1024).toFixed(1)} KB`;
  if (size < 1024 ** 3) return `${(size / 1024 ** 2).toFixed(1)} MB`;
  return `${(size / 1024 ** 3).toFixed(1)} GB`;
}

export function validateBackupSchedule(
  fields: UpdateBackupScheduleRequest,
): string {
  if (typeof fields.enabled !== "boolean")
    return "Choose whether automatic backups are enabled.";
  if (fields.frequency !== "Daily" && fields.frequency !== "Weekly")
    return "Choose a valid backup frequency.";
  if (
    typeof fields.time !== "string" ||
    !/^([01]\d|2[0-3]):[0-5]\d$/.test(fields.time)
  )
    return "Enter a valid backup time.";
  if (
    fields.frequency === "Weekly" &&
    (fields.dayOfWeek == null || !backupWeekdays.includes(fields.dayOfWeek))
  )
    return "Choose a day for weekly backups.";
  if (fields.frequency === "Daily" && fields.dayOfWeek != null)
    return "Daily backups do not require a weekday.";
  if (
    !Number.isSafeInteger(fields.retentionDays) ||
    fields.retentionDays < 1 ||
    fields.retentionDays > 365
  )
    return "Choose a retention period between 1 and 365 days.";
  return "";
}

export function getBackupHealthView(
  health: BackupHealthResponse,
  now = new Date(),
) {
  const zone = backupTimeZone(health.timeZone);
  const latest = health.latestSuccessfulBackup;
  const day = new Intl.DateTimeFormat("en-CA", {
    timeZone: zone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  });
  const completed = latest
    ? new Date(latest.completedAt || latest.dateTime)
    : null;
  const today =
    completed &&
    Number.isFinite(completed.getTime()) &&
    day.format(completed) === day.format(now);
  if (health.isRunning)
    return {
      state: "running",
      title: "Backup in progress",
      message:
        "Your backup is running. The history will update when it finishes.",
    };
  if (health.latestAttempt?.status === "Failed")
    return {
      state: "failed",
      title: "Latest backup failed",
      message:
        health.latestAttempt.errorMessage ||
        "The latest backup could not be completed. Try running a backup again.",
    };
  const scheduled = health.nextScheduledAt
    ? new Date(health.nextScheduledAt)
    : null;
  if (health.enabled && scheduled && scheduled <= now)
    return {
      state: "scheduled",
      title: "Scheduled backup pending",
      message: `The backup scheduled for ${formatBackupDate(health.nextScheduledAt, zone)} (${health.timeZoneDisplay || "Philippine Time (UTC+8)"}) is waiting to run.`,
    };
  if (today && completed)
    return {
      state: "success",
      title: "All systems protected",
      message: `Your latest backup completed successfully today at ${new Intl.DateTimeFormat("en-US", { timeZone: zone, hour: "numeric", minute: "2-digit", hour12: true }).format(completed)}.`,
    };
  if (!health.enabled)
    return {
      state: "disabled",
      title: "Automatic backups paused",
      message:
        "Automatic backups are disabled. Enable the schedule or use Back Up Now.",
    };
  if (
    health.nextScheduledAt &&
    formatBackupDate(health.nextScheduledAt, zone) !== "Unavailable"
  )
    return {
      state: "scheduled",
      title: "Waiting for scheduled backup",
      message: `Your backup will run at ${formatBackupDate(health.nextScheduledAt, zone)} (${health.timeZoneDisplay || "Philippine Time (UTC+8)"}).`,
    };
  return {
    state: "scheduled",
    title: "No backup completed today",
    message: "The next scheduled backup time is currently unavailable.",
  };
}

export function backupTypeLabel(type: BackupType): string {
  return type === "BeforeRestore" ? "Before restore" : type;
}

// The word the Head Admin types to confirm a restore; the server checks it again.
export const RESTORE_CONFIRMATION = "RESTORE";

export function canConfirmRestore(confirmation: string, password: string) {
  return confirmation === RESTORE_CONFIRMATION && password.length > 0;
}

export function restoreConfirmHint(confirmation: string, password: string) {
  const typed = confirmation === RESTORE_CONFIRMATION;
  if (!typed && !password)
    return "Type RESTORE in capital letters, then enter your password.";
  if (!typed) return "Type RESTORE in capital letters.";
  if (!password) return "Enter your password.";
  return "";
}

const restoreStepLabels: Record<RestoreStep, string> = {
  CheckBackup: "Checking the backup",
  SafetyBackup: "Making a safety backup of today's data",
  LoadBackup: "Loading the backup",
  SignEveryoneOut: "Signing everyone out",
  CountRecords: "Counting the records",
};

const countFormat = new Intl.NumberFormat("en-US");

// "ok": the latest progress was read. "unreachable": the server did not answer this time.
// "lost": the server no longer knows this restore (for example after a restart).
export type RestoreConnection = "ok" | "unreachable" | "lost";

export function getRestoreView(
  progress: BackupRestoreResponse,
  dateLabel: string,
  connection: RestoreConnection,
) {
  const steps = progress.steps.map((step) => ({
    step: step.step,
    label: restoreStepLabels[step.step] ?? step.step,
    state: step.state,
  }));
  const running = steps.findIndex((step) => step.state === "Running");
  const base = {
    dateLabel,
    steps,
    statusLine: "",
    note: "",
    counts: [] as [string, string, string][],
  };
  if (connection === "lost")
    return {
      ...base,
      title: "Restore result unknown",
      tone: "failed" as const,
      message:
        "The server no longer has this restore's progress. It may have restarted. Sign in again, then check the backup list and the audit log.",
      action: "signIn" as const,
    };
  if (progress.state === "Running")
    return {
      ...base,
      title: "Restoring a backup",
      tone: "running" as const,
      message:
        "This takes a few minutes. Other staff are paused until it ends. Keep this page open to see the result.",
      statusLine:
        running < 0
          ? "Starting…"
          : `Step ${running + 1} of ${steps.length}: ${steps[running].label}`,
      note:
        connection === "unreachable"
          ? "The server is not answering right now. Still checking…"
          : "",
      action: null,
    };
  const counts = progress.counts.map((count): [string, string, string] => [
    count.records,
    countFormat.format(count.before),
    count.after == null ? "—" : countFormat.format(count.after),
  ]);
  if (progress.state === "Finished")
    return {
      ...base,
      title: "Backup restored",
      tone: "success" as const,
      message: progress.message || "The backup was restored.",
      counts,
      action: "signIn" as const,
    };
  return {
    ...base,
    title: "Restore did not finish",
    tone: "failed" as const,
    message:
      progress.message ||
      "The restore did not finish. Today's data is unchanged.",
    action: "back" as const,
  };
}

export type RestoreView = ReturnType<typeof getRestoreView>;
