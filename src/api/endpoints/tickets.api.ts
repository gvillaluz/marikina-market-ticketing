import apiClient from '../client';
import type { PaginatedResponse } from '../types/common.types';
import type {
  InspectionRecord,
  WarningRecord,
  TicketRecord,
  PrintConfigPayload,
  ExportResult,
  CreateTicketPayload,
} from '../types/ticket.types';

export interface GetInspectionsParams {
  search?: string;
  type?: 'all' | 'warning' | 'ticket';
  section?: string;
  page?: number;
  pageSize?: number;
}

export const ticketsApi = {
  list(params: GetInspectionsParams): Promise<PaginatedResponse<TicketRecord>> {
    return apiClient.get('/inspections/tickets', { params }) as unknown as Promise<PaginatedResponse<TicketRecord>>;
  },

  getById(id: string): Promise<TicketRecord> {
    return apiClient.get(`/inspections/tickets/${id}`) as unknown as Promise<TicketRecord>;
  },

  create(payload: CreateTicketPayload): Promise<TicketRecord> {
    return apiClient.post('/inspections/tickets', payload) as unknown as Promise<TicketRecord>;
  },

  updateStatus(id: string, status: string): Promise<TicketRecord> {
    return apiClient.patch(`/inspections/tickets/${id}/status`, { status }) as unknown as Promise<TicketRecord>;
  },

  getHistory(ticketId: string): Promise<unknown[]> {
    return apiClient.get(`/inspections/tickets/${ticketId}/history`) as unknown as Promise<unknown[]>;
  },
};

export function getInspections(
  params: GetInspectionsParams
): Promise<PaginatedResponse<InspectionRecord>> {
  return apiClient.get('/inspections', { params }) as unknown as Promise<PaginatedResponse<InspectionRecord>>;
}

export function getInspectionById(id: string): Promise<InspectionRecord> {
  return apiClient.get(`/inspections/${id}`) as unknown as Promise<InspectionRecord>;
}

export function getWarningById(id: string): Promise<WarningRecord> {
  return apiClient.get(`/inspections/warnings/${id}`) as unknown as Promise<WarningRecord>;
}

export function getTicketById(id: string): Promise<TicketRecord> {
  return apiClient.get(`/inspections/tickets/${id}`) as unknown as Promise<TicketRecord>;
}

export function exportInspections(
  payload: PrintConfigPayload
): Promise<Blob | ExportResult> {
  return apiClient.post('/inspections/export', payload, {
    responseType: 'blob',
  }) as unknown as Promise<Blob | ExportResult>;
}