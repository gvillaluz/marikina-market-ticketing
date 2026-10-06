import apiClient from "../client";
import { CountResponse } from "../types/admin-configuration.types";

export const adminConfigurationsApi = {
  marketSectionSummary() {
    return apiClient
      .get<CountResponse>("/marketSection/count")
      .then((response) => response.data as CountResponse);
  },

  ordinanceSummary() {
    return apiClient
      .get<CountResponse>("/ordinance/count")
      .then((response) => response.data as CountResponse);
  },
};
