import apiClient from "@/api/client";
import { ApiRequestError } from "@/utils/apiErrors";
import type {
  BackupHealthResponse,
  BackupPageResponse,
  BackupResponse,
  BackupScheduleResponse,
  UpdateBackupScheduleRequest,
} from "../types/backups.types";

const path = "/admin/backups";

function normalizeSchedule(
  response: BackupScheduleResponse,
): BackupScheduleResponse {
  if (
    !response ||
    typeof response.time !== "string" ||
    typeof response.enabled !== "boolean" ||
    !Number.isSafeInteger(response.retentionDays) ||
    response.retentionDays <= 0 ||
    !["Daily", "Weekly"].includes(response.frequency)
  )
    throw new ApiRequestError();
  // A global enum converter may also return the weekday as its C# name.
  const day: unknown = response.dayOfWeek;
  const weekdays = [
    "Sunday",
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
  ];
  const dayOfWeek =
    typeof day === "string" ? weekdays.indexOf(day) : response.dayOfWeek;
  if (
    dayOfWeek != null &&
    (!Number.isInteger(dayOfWeek) || dayOfWeek < 0 || dayOfWeek > 6)
  )
    throw new ApiRequestError();
  const time = /^([01]\d|2[0-3]):[0-5]\d(?::00)?$/.test(response.time)
    ? response.time.slice(0, 5)
    : response.time;
  if (!/^([01]\d|2[0-3]):[0-5]\d$/.test(time)) throw new ApiRequestError();
  return { ...response, dayOfWeek, time };
}

export const backupsApi = {
  async getSchedule(signal?: AbortSignal): Promise<BackupScheduleResponse> {
    const response = await apiClient.get<BackupScheduleResponse>(
      `${path}/schedule`,
      { signal },
    );
    return normalizeSchedule(response.data);
  },
  async updateSchedule(
    request: UpdateBackupScheduleRequest,
  ): Promise<BackupScheduleResponse> {
    // Send serialized DTO fields so the shared interceptor does not snake-case them.
    const response = await apiClient.put<BackupScheduleResponse>(
      `${path}/schedule`,
      JSON.stringify({
        Enabled: request.enabled,
        Frequency: request.frequency,
        DayOfWeek: request.dayOfWeek,
        Time: request.time,
        RetentionDays: request.retentionDays,
      }),
    );
    return normalizeSchedule(response.data);
  },
  async getHealth(signal?: AbortSignal): Promise<BackupHealthResponse> {
    const response = await apiClient.get<BackupHealthResponse>(
      `${path}/health`,
      { signal },
    );
    if (
      !response.data ||
      typeof response.data.isRunning !== "boolean" ||
      typeof response.data.enabled !== "boolean"
    )
      throw new ApiRequestError();
    return response.data;
  },
  async getHistory(
    offset: number,
    signal?: AbortSignal,
  ): Promise<BackupPageResponse> {
    if (!Number.isSafeInteger(offset) || offset < 0)
      throw new ApiRequestError();
    const response = await apiClient.get<BackupPageResponse>(path, {
      params: { offset },
      signal,
    });
    if (
      !response.data ||
      !Array.isArray(response.data.items) ||
      typeof response.data.hasMore !== "boolean"
    )
      throw new ApiRequestError();
    return response.data;
  },
  async createManual(): Promise<BackupResponse> {
    const response = await apiClient.post<BackupResponse>(path);
    return response.data;
  },
};
