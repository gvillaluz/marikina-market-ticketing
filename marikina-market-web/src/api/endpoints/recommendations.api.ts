import client from "@/api/client";
import type { RecommendationsResponse } from "@/api/types/recommendations.types";

export const recommendationsApi = {
  async getRecommendations(): Promise<RecommendationsResponse> {
    const { data } = await client.get<RecommendationsResponse>(
      "/admin/recommendations",
    );
    return data;
  },
};
