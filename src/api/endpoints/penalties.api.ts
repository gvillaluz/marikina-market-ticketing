import client from '@/api/client';
import type { ApiResponse, PaginatedResponse } from '@/api/types/common.types';

export interface Penalty {
  id: string;
  invoiceNumber: string;
  vendorId: string;
  vendorName: string;
  ticketId?: string;
  ticketNumber?: string;
  description: string;
  amount: number;
  status: 'paid' | 'unpaid';
  issuedAt: string;
  dueDate: string;
  paidAt?: string;
}

export interface PenaltySummary {
  totalUnpaid: number;
  totalCollected: number;
  pendingCount: number;
  overdueCount: number;
}

/** Penalty / fine API endpoints. */
export const penaltiesApi = {
  async list(params: { page?: number; pageSize?: number; status?: string } = {}): Promise<PaginatedResponse<Penalty>> {
    const { data } = await client.get<ApiResponse<PaginatedResponse<Penalty>>>('/penalties', { params });
    return data.data;
  },

  async getSummary(): Promise<PenaltySummary> {
    const { data } = await client.get<ApiResponse<PenaltySummary>>('/penalties/summary');
    return data.data;
  },

  async markPaid(id: string): Promise<Penalty> {
    const { data } = await client.patch<ApiResponse<Penalty>>(`/penalties/${id}/pay`);
    return data.data;
  },
};
