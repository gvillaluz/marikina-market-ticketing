import apiClient from "../client";
import { ApiRequestError } from "@/utils/apiErrors";
import type {
  MarketSectionResponse,
  SaveMarketSectionRequest,
} from "../types/market-section.types";

export const marketSectionApi = {
  async create(
    request: SaveMarketSectionRequest,
  ): Promise<MarketSectionResponse> {
    const response = await apiClient.post<MarketSectionResponse>(
      "/marketsection",
      request,
    );
    return response.data;
  },
  async update(
    id: number,
    request: SaveMarketSectionRequest,
  ): Promise<MarketSectionResponse> {
    const response = await apiClient.put<MarketSectionResponse>(
      `/marketsection/${id}`,
      request,
    );
    return response.data;
  },
  async updateActive(id: number, isActive: boolean): Promise<void> {
    await apiClient.patch(`/marketsection/${id}/active`, { isActive });
  },
  async getAll(signal?: AbortSignal): Promise<MarketSectionResponse[]> {
    const response = await apiClient.get<MarketSectionResponse[]>(
      "/marketsection",
      { signal },
    );
    if (
      !Array.isArray(response.data) ||
      !response.data.every(
        (section) =>
          section &&
          Number.isSafeInteger(section.id) &&
          section.id > 0 &&
          typeof section.name === "string" &&
          typeof section.description === "string" &&
          typeof section.isActive === "boolean" &&
          Number.isSafeInteger(section.vendorCount) &&
          section.vendorCount >= 0,
      )
    )
      throw new ApiRequestError(
        "Unable to load market sections. Please try again.",
      );
    return response.data;
  },
};
