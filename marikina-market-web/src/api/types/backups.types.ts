export type BackupFrequency = "Daily" | "Weekly";
export type BackupWeekday =
  | "Sunday"
  | "Monday"
  | "Tuesday"
  | "Wednesday"
  | "Thursday"
  | "Friday"
  | "Saturday";
export type BackupType = "Automatic" | "Manual" | "BeforeRestore";
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

export interface RestoreBackupRequest {
  confirmation: string;
  password: string;
}

export type RestoreState = "Running" | "Finished" | "Failed";
export type RestoreStep =
  | "CheckBackup"
  | "SafetyBackup"
  | "LoadBackup"
  | "SignEveryoneOut"
  | "CountRecords";
export type RestoreStepState = "Waiting" | "Running" | "Done" | "Failed";
export type RestoreCount = "Tickets" | "Businesses" | "People" | "Accounts";

export interface BackupRestoreResponse {
  restoreId: string;
  // Both null when the backup is an uploaded file; fileName is then its name.
  backupId: number | null;
  backupDateTime: string | null;
  fileName: string | null;
  state: RestoreState;
  steps: { step: RestoreStep; state: RestoreStepState }[];
  counts: { records: RestoreCount; before: number; after: number | null }[];
  safetyBackupId: number | null;
  message: string | null;
  startedAt: string;
  finishedAt: string | null;
}
