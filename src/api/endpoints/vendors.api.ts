import client from '@/api/client';
import type { Vendor, VendorRegistrationInput } from '@/api/types/vendor.types';
import type { ApiResponse, PaginatedResponse, PaginationParams } from '@/api/types/common.types';
import type { Status } from '@/api/types/common.types';

/** Vendor API endpoints for the ASP.NET backend. */
export const vendorsApi = {
  async list(params: PaginationParams & { status?: Status } = {}): Promise<PaginatedResponse<Vendor>> {
    const { data } = await client.get<ApiResponse<PaginatedResponse<Vendor>>>('/vendors', { params });
    return data.data;
  },

  async getById(id: string): Promise<Vendor> {
    const { data } = await client.get<ApiResponse<Vendor>>(`/vendors/${id}`);
    return data.data;
  },

  async getMyProfile(): Promise<Vendor> {
    const { data } = await client.get<ApiResponse<Vendor>>('/vendors/me');
    return data.data;
  },

  async register(input: VendorRegistrationInput): Promise<Vendor> {
    const { data } = await client.post<ApiResponse<Vendor>>('/vendors/register', input);
    return data.data;
  },

  async approve(id: string): Promise<Vendor> {
    const { data } = await client.patch<ApiResponse<Vendor>>(`/vendors/${id}/approve`);
    return data.data;
  },

  async reject(id: string, reason?: string): Promise<Vendor> {
    const { data } = await client.patch<ApiResponse<Vendor>>(`/vendors/${id}/reject`, { reason });
    return data.data;
  },

  async suspend(id: string): Promise<Vendor> {
    const { data } = await client.patch<ApiResponse<Vendor>>(`/vendors/${id}/suspend`);
    return data.data;
  },
};
