import client from "@/api/client";
import type { DashboardSummary } from "@/api/types/dashboard.types";

export const dashboardApi = {
  async getSummary(signal?: AbortSignal): Promise<DashboardSummary> {
    const { data } = await client.get<DashboardSummary>("/dashboard/summary", {
      signal,
    });
    return data;
  },
};
