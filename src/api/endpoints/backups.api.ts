import apiClient from "../client";
import { ApiRequestError } from "@/utils/apiErrors";
import type {
  BackupDownloadResponse,
  BackupHealthResponse,
  BackupPageResponse,
  BackupResponse,
  BackupScheduleResponse,
  UpdateBackupScheduleRequest,
} from "../types/backups.types";

const path = "/admin/backups";

function getDownloadFileName(value: unknown, id: number): string {
  if (typeof value !== "string") return `backup-${id}.enc`;
  const encodedName = value.match(/filename\*=UTF-8''([^;]+)/i)?.[1];
  let name = value.match(/filename="?([^";]+)"?/i)?.[1];
  if (encodedName) {
    try {
      name = decodeURIComponent(encodedName);
    } catch {
      // Use the plain filename or fallback if the encoded name is invalid.
    }
  }
  return (
    name?.replace(/[\\/:*?"<>|\x00-\x1f\x7f]/g, "_").trim() ||
    `backup-${id}.enc`
  );
}

export const backupsApi = {
  async getSchedule(signal?: AbortSignal): Promise<BackupScheduleResponse> {
    const response = await apiClient.get<BackupScheduleResponse>(
      `${path}/schedule`,
      { signal },
    );
    return response.data;
  },
  async updateSchedule(
    request: UpdateBackupScheduleRequest,
  ): Promise<BackupScheduleResponse> {
    const response = await apiClient.put<BackupScheduleResponse>(
      `${path}/schedule`,
      request,
    );
    return response.data;
  },
  async getHealth(signal?: AbortSignal): Promise<BackupHealthResponse> {
    const response = await apiClient.get<BackupHealthResponse>(
      `${path}/health`,
      { signal },
    );
    return response.data;
  },
  async getHistory(
    offset: number,
    signal?: AbortSignal,
  ): Promise<BackupPageResponse> {
    const response = await apiClient.get<BackupPageResponse>(path, {
      params: { offset },
      signal,
    });
    return response.data;
  },
  async createManual(): Promise<BackupResponse> {
    const response = await apiClient.post<BackupResponse>(path);
    return response.data;
  },
  async download(id: number): Promise<BackupDownloadResponse> {
    if (!Number.isSafeInteger(id) || id <= 0) throw new ApiRequestError();
    const response = await apiClient.get<ArrayBuffer>(
      `${path}/${id}/download`,
      {
        responseType: "arraybuffer",
        // Decode error bodies before the shared interceptor extracts the server message.
        transformResponse: [
          (data: ArrayBuffer, _headers, status) => {
            if (status !== undefined && status >= 400) {
              const message = new TextDecoder().decode(data);
              try {
                return JSON.parse(message) as unknown;
              } catch {
                return message;
              }
            }
            return data;
          },
        ],
      },
    );
    return {
      blob: new Blob([response.data], { type: "application/octet-stream" }),
      fileName: getDownloadFileName(
        response.headers["content-disposition"],
        id,
      ),
    };
  },
};
