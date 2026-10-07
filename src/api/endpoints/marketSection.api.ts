import apiClient from '../client';
import type { MarketSectionResponse, SaveMarketSectionRequest } from '../types/market-section.types';

export const marketSectionApi = {
  async create(request: SaveMarketSectionRequest): Promise<MarketSectionResponse> {
    const response = await apiClient.post<MarketSectionResponse>('/marketsection', request);
    return response.data;
  },
  async update(id: number, request: SaveMarketSectionRequest): Promise<MarketSectionResponse> {
    const response = await apiClient.put<MarketSectionResponse>(`/marketsection/${id}`, request);
    return response.data;
  },
  async updateActive(id: number, isActive: boolean): Promise<void> {
    await apiClient.patch(`/marketsection/${id}/active`, JSON.stringify({ IsActive: isActive }));
  },
  async getAll(signal?: AbortSignal): Promise<MarketSectionResponse[]> {
    const response = await apiClient.get<MarketSectionResponse[]>('/marketsection', { signal });
    return response.data;
  },
};
