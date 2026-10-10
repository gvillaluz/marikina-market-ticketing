import apiClient from "../client";
import type {
  OrdinanceDetailResponse,
  OrdinanceSummaryResponse,
  SaveOrdinanceRequest,
} from "../types/ordinance.types";
import { ApiRequestError, getApiResponseMessage } from "@/utils/apiErrors";

function validId(id: number) {
  if (!Number.isSafeInteger(id) || id <= 0) throw new ApiRequestError();
}

export const ordinanceApi = {
  async getAll(signal?: AbortSignal): Promise<OrdinanceSummaryResponse[]> {
    const response = await apiClient.get<OrdinanceSummaryResponse[] | string>(
      "/ordinance",
      {
        signal,
        validateStatus: (code) => (code >= 200 && code < 300) || code === 404,
      },
    );
    if (response.status === 404) {
      const message = getApiResponseMessage(response.data);
      throw new ApiRequestError(message);
    }
    if (!Array.isArray(response.data)) {
      throw new ApiRequestError(getApiResponseMessage(response.data));
    }
    return response.data;
  },
  async getById(
    id: number,
    signal?: AbortSignal,
  ): Promise<OrdinanceDetailResponse> {
    validId(id);
    const response = await apiClient.get<OrdinanceDetailResponse>(
      `/ordinance/${id}`,
      { signal },
    );
    return response.data;
  },
  async create(
    request: SaveOrdinanceRequest,
  ): Promise<OrdinanceSummaryResponse> {
    const response = await apiClient.post<OrdinanceSummaryResponse>(
      "/ordinance",
      request,
    );
    return response.data;
  },
  async update(
    id: number,
    request: SaveOrdinanceRequest,
  ): Promise<OrdinanceSummaryResponse> {
    validId(id);
    const response = await apiClient.put<OrdinanceSummaryResponse>(
      `/ordinance/${id}`,
      request,
    );
    return response.data;
  },
};
