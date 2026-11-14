import apiClient from "../client";
import type { PaginatedResponse, RecordStatus } from "../types/common.types";
import type {
  InspectionRecord,
  WarningRecord,
  TicketRecord,
  TicketHistoryEntry,
  TicketSummary,
  TicketStats,
  TicketDetail,
  InspectionSummary,
  TicketStatusUpdateResponse,
  PersonTicketHistoryItem,
} from "../types/ticket.types";
import { ApiRequestError } from "@/utils/apiErrors";

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
    return payload as TicketRecord;
  });
}

export const ticketsApi = {
  getPersonHistory(personId: number, offset = 0): Promise<PaginatedResponse<PersonTicketHistoryItem>> {
    if (!Number.isSafeInteger(personId) || personId <= 0 || !Number.isSafeInteger(offset) || offset < 0) {
      return Promise.reject(new ApiRequestError("Invalid person or history offset.", 400));
    }
    return apiClient.get(`/persons/${personId}/tickets`, { params: { offset } })
      .then(response => response.data as PaginatedResponse<PersonTicketHistoryItem>);
  },
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
    if (!Number.isSafeInteger(id) || id <= 0) {
      return Promise.reject(new ApiRequestError("Invalid ticket ID.", 400));
    }
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
  }: UpdateStatusParams): Promise<TicketStatusUpdateResponse> {
    if (
      !Number.isSafeInteger(ticketId) ||
      ticketId <= 0 ||
      !Number.isSafeInteger(version) ||
      version < 0 ||
      version > 0xffffffff ||
      ![
        "Pending",
        "Paid",
        "Cleared",
        "Waived",
        "Contested",
        "Overdue",
        "InProgress",
      ].includes(newStatus)
    ) {
      return Promise.reject(
        new ApiRequestError("Invalid ticket status update.", 400),
      );
    }
    return apiClient
      .patch(`/admin/tickets/${ticketId}/update-status`, { newStatus, version })
      .then((response) => response.data as TicketStatusUpdateResponse);
  },

  getHistory(ticketId: number): Promise<TicketHistoryEntry[]> {
    if (!Number.isSafeInteger(ticketId) || ticketId <= 0) {
      return Promise.reject(new ApiRequestError("Invalid ticket ID.", 400));
    }
    return apiClient
      .get(`/admin/tickets/${ticketId}/history`)
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
    return payload as WarningRecord;
  });
}
