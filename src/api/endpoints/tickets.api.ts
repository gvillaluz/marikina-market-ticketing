
import apiClient from "../client";
import type { PaginatedResponse, RecordStatus } from "../types/common.types";
import type { InspectionRecord, WarningRecord, TicketRecord, PrintConfigPayload, ExportResult, TicketHistoryEntry, TicketSummary, TicketStats, TicketDetail, InspectionSummary } from "../types/ticket.types";

interface GetInspectionsParams {
  search?: string;
  type?: "Warning" | "Ticket";
  offset?: number;
  marketSectionId?: number;
}

interface GetTicketsParams {
  offset?: number;
  search?: string;
  status?: RecordStatus;
  marketSectionId?: number;
}

interface UpdateStatusParams {
  ticketId: number;
  newStatus: RecordStatus;
  version: number;
}

export function getTicketById(id: string): Promise<TicketRecord> {
  return apiClient.get(`/admin/tickets/inspections/${id}`).then((response) => {
    const payload =
      (response.data as { data?: TicketRecord }).data ?? response.data;
    console.log("Ticket detail API data:", payload);
    return payload as TicketRecord;
  });
}

export const ticketsApi = {
  inspectionList(
    params: GetInspectionsParams,
  ): Promise<PaginatedResponse<InspectionSummary>> {
    return apiClient
      .get("/admin/tickets/inspections", { params })
      .then(
        (response) => response.data as PaginatedResponse<InspectionSummary>,
      );
  },

  ticketList(
    params: GetTicketsParams,
  ): Promise<PaginatedResponse<TicketSummary>> {
    return apiClient
      .get("/admin/tickets", { params })
      .then((response) => response.data as PaginatedResponse<TicketSummary>);
  },

  getTicketAnalytics(): Promise<TicketStats> {
    return apiClient
      .get("/admin/tickets/analytics")
      .then((response) => response.data as TicketStats);
  },

  getTicketDetailById(id: number): Promise<TicketDetail> {
    return apiClient
      .get(`/admin/tickets/${id}`)
      .then((response) => response.data as TicketDetail);
  },

  getById(id: string): Promise<TicketRecord> {
    return apiClient
      .get(`/admin/tickets/inspections/${id}`)
      .then((response) => response.data as TicketRecord);
  },

  updateStatus({
    ticketId,
    newStatus,
    version,
  }: UpdateStatusParams): Promise<TicketDetail> {
    return apiClient
      .patch(`/admin/tickets/${ticketId}/update-status`, { newStatus, version })
      .then((response) => response.data as TicketDetail);
  },

  getHistory(ticketId: string): Promise<TicketHistoryEntry[]> {
    return apiClient
      .get(`/admin/tickets/inspections/${ticketId}/history`)
      .then((response) => response.data as TicketHistoryEntry[]);
  },
};

export function getInspections(
  params: GetInspectionsParams,
): Promise<PaginatedResponse<InspectionRecord>> {
  return apiClient
    .get("/admin/tickets/inspections", { params })
    .then((response) => response.data as PaginatedResponse<InspectionRecord>);
}

export function getInspectionById(id: string): Promise<InspectionRecord> {
  return apiClient
    .get(`/admin/tickets/inspections/${id}`)
    .then((response) => response.data as InspectionRecord);
}

export function getWarningById(id: string): Promise<WarningRecord> {
  return apiClient.get(`/admin/tickets/inspections/${id}`).then((response) => {
    const payload =
      (response.data as { data?: WarningRecord }).data ?? response.data;
    console.log("Warning detail API data:", payload);
    return payload as WarningRecord;
  });
}

export function exportInspections(
  payload: PrintConfigPayload,
): Promise<ExportResult | ExportBlobResult> {
  return apiClient
    .post<Blob>("/inspections/export", payload, {
      responseType: "blob",
    })
    .then(async (response) => {
      const contentTypeHeader = response.headers["content-type"];
      const contentDispositionHeader = response.headers["content-disposition"];
      const contentType =
        typeof contentTypeHeader === "string" ? contentTypeHeader : "";
      const contentDisposition =
        typeof contentDispositionHeader === "string"
          ? contentDispositionHeader
          : undefined;
      if (contentType.includes("json")) {
        return parseExportResult(
          JSON.parse(await response.data.text()) as unknown,
        );
      }

      return {
        blob: response.data,
        fileName: getDownloadFileName(contentDisposition, contentType),
      };
    });
}

export interface ExportBlobResult {
  blob: Blob;
  fileName: string;
}

function getDownloadFileName(
  contentDisposition: string | undefined,
  contentType: string,
): string {
  const encodedName = contentDisposition?.match(
    /filename\*=UTF-8''([^;]+)/i,
  )?.[1];
  const plainName = contentDisposition?.match(/filename="?([^";]+)"?/i)?.[1];
  let suppliedName = plainName;
  if (encodedName) {
    try {
      suppliedName = decodeURIComponent(encodedName);
    } catch {
      suppliedName = encodedName;
    }
  }
  if (suppliedName) return suppliedName.replace(/[\\/:*?"<>|]/g, "_");

  const extension = contentType.includes("pdf")
    ? "pdf"
    : contentType.includes("spreadsheet") || contentType.includes("excel")
      ? "xlsx"
      : contentType.includes("csv")
        ? "csv"
        : "bin";
  return `market-records-export-${Date.now()}.${extension}`;
}

function parseExportResult(value: unknown): ExportResult {
  if (typeof value !== "object" || value === null) {
    throw new Error(
      "The export service returned an invalid download response.",
    );
  }

  const result = value as Record<string, unknown>;
  if (
    typeof result.fileUrl !== "string" ||
    typeof result.fileName !== "string"
  ) {
    throw new Error("The export service did not provide a downloadable file.");
  }

  return { fileUrl: result.fileUrl, fileName: result.fileName };
}
