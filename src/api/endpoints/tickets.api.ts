import { TicketStatus } from '@/features/tickets/tickets.types';
import apiClient from '../client';
import type { PaginatedResponse, RecordStatus } from '../types/common.types';
import type {
  InspectionRecord,
  WarningRecord,
  TicketRecord,
  PrintConfigPayload,
  ExportResult,
  CreateTicketPayload,
  TicketListResponse,
  TicketHistoryEntry,
  TicketSummary,
  TicketStats,
  TicketDetail,
} from '../types/ticket.types';

export interface GetInspectionsParams {
  search?: string;
  type?: 'all' | 'warning' | 'ticket';
  section?: string;
  page?: number;
  pageSize?: number;
  offset?: number;
  status?: string;
  market_section?: string;
  market_section_id?: number;
}

export interface GetTicketsParams {
  search?: string,
  status?: RecordStatus
  market_section_id?: number
}

interface UpdateStatusParams {
  ticketId: number;
  newStatus: RecordStatus;
  version: number;
}

export interface GetTicketsParams extends GetInspectionsParams { marketSection?: string }

export function getTickets(params: GetTicketsParams): Promise<TicketListResponse> {
  return apiClient.get('/admin/tickets/inspections', { params: { offset: 0, ...params } }).then((response) => {
    console.log('Tickets API data:', response.data);
    return response.data as TicketListResponse;
  });
}

export function getTicketById(id: string): Promise<TicketRecord> {
  return apiClient.get(`/admin/tickets/inspections/${id}`).then((response) => {
    const payload = (response.data as { data?: TicketRecord }).data ?? response.data;
    console.log('Ticket detail API data:', payload);
    return payload as TicketRecord;
  });
}

export function updateTicketStatus(id: string, status: string): Promise<TicketRecord> {
  return apiClient.patch(`/admin/tickets/inspections/${id}/status`, { status }).then((response) => response.data as TicketRecord);
}

export const ticketsApi = {
  inspectionList(params: GetInspectionsParams): Promise<PaginatedResponse<TicketRecord>> {
    return apiClient.get('/admin/inspections', { params }).then((response) => response.data as PaginatedResponse<TicketRecord>);
  },

  ticketList(params: GetTicketsParams): Promise<PaginatedResponse<TicketSummary>> {
    return apiClient.get('/admin/tickets', { params }).then((response) => response.data as PaginatedResponse<TicketSummary>);
  },

  getTicketAnalytics(): Promise<TicketStats> {
    return apiClient.get('/admin/tickets/analytics').then((response) => response.data as TicketStats);
  },

  getTicketDetailById(id: number): Promise<TicketDetail> {
    return apiClient.get(`/admin/tickets/${id}`).then((response) => response.data as TicketDetail);
  },

  getById(id: string): Promise<TicketRecord> {
    return apiClient.get(`/admin/tickets/inspections/${id}`).then((response) => response.data as TicketRecord);
  },
  
  updateStatus({ ticketId, newStatus, version }: UpdateStatusParams): Promise<TicketDetail> {
    return apiClient.patch(`/admin/tickets/${ticketId}/update-status`, { newStatus, version }).then((response) => response.data as TicketDetail);
  },

  getHistory(ticketId: string): Promise<TicketHistoryEntry[]> {
    return apiClient.get(`/admin/tickets/inspections/${ticketId}/history`).then((response) => response.data as TicketHistoryEntry[]);
  },
};

export function getInspections(
  params: GetInspectionsParams
): Promise<PaginatedResponse<InspectionRecord>> {
  return apiClient.get('/admin/tickets/inspections', { params }).then((response) => response.data as PaginatedResponse<InspectionRecord>);
}

export function getInspectionById(id: string): Promise<InspectionRecord> {
  return apiClient.get(`/admin/tickets/inspections/${id}`).then((response) => response.data as InspectionRecord);
}

export function getWarningById(id: string): Promise<WarningRecord> {
  return apiClient.get(`/admin/tickets/inspections/${id}`).then((response) => {
    const payload = (response.data as { data?: WarningRecord }).data ?? response.data;
    console.log('Warning detail API data:', payload);
    return payload as WarningRecord;
  });
}

export function exportInspections(
  payload: PrintConfigPayload
): Promise<Blob | ExportResult> {
  return apiClient.post('/inspections/export', payload, {
    responseType: 'blob',
  }) as unknown as Promise<Blob | ExportResult>;
}