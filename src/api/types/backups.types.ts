export type BackupFrequency = "Daily" | "Weekly";
export type BackupWeekday =
  | "Sunday"
  | "Monday"
  | "Tuesday"
  | "Wednesday"
  | "Thursday"
  | "Friday"
  | "Saturday";
export type BackupType = "Automatic" | "Manual";
export type BackupStatus = "Completed" | "Failed";

export interface BackupResponse {
  id: number;
  dateTime: string;
  type: BackupType;
  size: number;
  status: BackupStatus;
  completedAt: string | null;
  expiresAt: string | null;
  errorMessage: string | null;
  canDownload: boolean;
  downloadRoute: string | null;
}

export interface BackupPageResponse {
  items: BackupResponse[];
  hasMore: boolean;
  total: number | null;
}

export interface BackupDownloadResponse {
  blob: Blob;
  fileName: string;
}

export interface UpdateBackupScheduleRequest {
  enabled: boolean;
  frequency: BackupFrequency;
  dayOfWeek: BackupWeekday | null;
  time: string;
  retentionDays: number;
}

export interface BackupScheduleResponse extends UpdateBackupScheduleRequest {
  timeZone: string;
  timeZoneDisplay: string;
}

export interface BackupHealthResponse {
  latestAttempt: BackupResponse | null;
  latestSuccessfulBackup: BackupResponse | null;
  isRunning: boolean;
  enabled: boolean;
  retentionDays: number;
  nextScheduledAt: string | null;
  timeZone: string;
  timeZoneDisplay: string;
}
