import { ApiRequestError } from "@/utils/apiErrors";
import type {
  BackupHealthResponse,
  UpdateBackupScheduleRequest,
} from "@/api/types/backups.types";

export const backupKeys = {
  schedule: ["backups", "schedule"] as const,
  health: ["backups", "health"] as const,
  history: ["backups", "history"] as const,
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
  if (!/^([01]\d|2[0-3]):[0-5]\d$/.test(fields.time))
    return "Enter a valid backup time.";
  if (
    fields.frequency === "Weekly" &&
    (fields.dayOfWeek === null ||
      !Number.isInteger(fields.dayOfWeek) ||
      fields.dayOfWeek < 0 ||
      fields.dayOfWeek > 6)
  )
    return "Choose a day for weekly backups.";
  if (!Number.isSafeInteger(fields.retentionDays) || fields.retentionDays <= 0)
    return "Choose a valid retention period.";
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
