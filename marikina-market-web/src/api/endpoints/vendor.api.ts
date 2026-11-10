import client from "@/api/client";
import type { Vendor } from "@/api/types/vendor.types";
import type {
  ApiResponse,
  PaginatedResponse,
  PaginationParams,
} from "@/api/types/common.types";
import type { Status } from "@/api/types/common.types";

export const vendorApi = {
  async list(
    params: PaginationParams & { status?: Status } = {},
  ): Promise<PaginatedResponse<Vendor>> {
    const { data } = await client.get<ApiResponse<PaginatedResponse<Vendor>>>(
      "/vendors",
      { params },
    );
    return data.data;
  },

  async getById(id: string): Promise<Vendor> {
    const { data } = await client.get<ApiResponse<Vendor>>(`/vendor/${id}`);
    return data.data;
  },

  async getMyProfile(): Promise<Vendor> {
    const { data } = await client.get<ApiResponse<Vendor>>("/vendor/me");
    return data.data;
  },

  async approve(id: string): Promise<Vendor> {
    const { data } = await client.patch<ApiResponse<Vendor>>(
      `/vendor/${id}/approve`,
    );
    return data.data;
  },

  async reject(id: string, reason?: string): Promise<Vendor> {
    const { data } = await client.patch<ApiResponse<Vendor>>(
      `/vendor/${id}/reject`,
      { reason },
    );
    return data.data;
  },

  async suspend(id: string): Promise<Vendor> {
    const { data } = await client.patch<ApiResponse<Vendor>>(
      `/vendor/${id}/suspend`,
    );
    return data.data;
  },
};
