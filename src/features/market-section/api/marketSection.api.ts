import apiClient from "@/api/client";

export interface MarketSectionResponse {
  id: number;
  name: string;
  description: string;
  isActive: boolean;
  vendorCount: number;
}

export const marketSectionApi = {
  async getAll(signal?: AbortSignal): Promise<MarketSectionResponse[]> {
    const response = await apiClient.get<MarketSectionResponse[]>("/marketsection", { signal });
    return response.data;
  },
};
