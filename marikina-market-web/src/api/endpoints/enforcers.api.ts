import { AccountStatus, PaginatedResponse } from "../types/common.types";
import apiClient from "../client";
import {
  EnforcerActivityData,
  EnforcerPerformanceData,
  EnforcerProfile,
  EnforcerSummary,
  InspectionHistorySummary,
} from "../types/enforcer.types";

export interface GetEnforcerParams {
  offset?: number;
  search?: string;
  status?: AccountStatus;
  sortBy?: string;
  sortDirection?: "asc" | "desc";
}

export interface GetInspectionHistoryParams {
  offset: number;
}

export const enforcersApi = {
  enforcerList(
    params: GetEnforcerParams,
  ): Promise<PaginatedResponse<EnforcerSummary>> {
    return apiClient
      .get("/admin/enforcers", { params })
      .then((response) => response.data as PaginatedResponse<EnforcerSummary>);
  },

  enforcersActivity(): Promise<EnforcerActivityData> {
    return apiClient
      .get("/admin/enforcers/activities")
      .then((response) => response.data as EnforcerActivityData);
  },

  enforcerProfile(enforcerId: number): Promise<EnforcerProfile> {
    return apiClient
      .get(`/admin/enforcers/profile/${enforcerId}`)
      .then((response) => response.data as EnforcerProfile);
  },

  enforcerPerformance(enforcerId: number): Promise<EnforcerPerformanceData> {
    return apiClient
      .get(`/admin/enforcers/performance-summary/${enforcerId}`)
      .then((response) => response.data as EnforcerPerformanceData);
  },

  enforcerHistory(
    enforcerId: number,
    params: GetInspectionHistoryParams,
  ): Promise<PaginatedResponse<InspectionHistorySummary>> {
    return apiClient
      .get(`/admin/enforcers/${enforcerId}/inspections/history`, { params })
      .then(
        (response) =>
          response.data as PaginatedResponse<InspectionHistorySummary>,
      );
  },
};
