import client from '@/api/client';
import type { CreateTicketInput, Ticket, TicketHistoryEntry } from '@/api/types/ticket.types';
import type { ApiResponse, PaginatedResponse, PaginationParams } from '@/api/types/common.types';
import type { Status } from '@/api/types/common.types';

/** Ticket API endpoints for the ASP.NET backend. */
export const ticketsApi = {
  async list(params: PaginationParams & { status?: Status; type?: string } = {}): Promise<PaginatedResponse<Ticket>> {
    const { data } = await client.get<ApiResponse<PaginatedResponse<Ticket>>>('/tickets', { params });
    return data.data;
  },

  async getById(id: string): Promise<Ticket> {
    const { data } = await client.get<ApiResponse<Ticket>>(`/tickets/${id}`);
    return data.data;
  },

  async create(input: CreateTicketInput): Promise<Ticket> {
    const { data } = await client.post<ApiResponse<Ticket>>('/tickets', input);
    return data.data;
  },

  async updateStatus(id: string, status: Status): Promise<Ticket> {
    const { data } = await client.patch<ApiResponse<Ticket>>(`/tickets/${id}/status`, { status });
    return data.data;
  },

  async getHistory(id: string): Promise<TicketHistoryEntry[]> {
    const { data } = await client.get<ApiResponse<TicketHistoryEntry[]>>(`/tickets/${id}/history`);
    return data.data;
  },
};
