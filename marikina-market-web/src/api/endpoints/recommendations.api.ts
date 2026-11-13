import client from "@/api/client";
import type {
  RecommendationReview,
  RecommendationsResponse,
} from "@/api/types/recommendations.types";

export const recommendationsApi = {
  async getRecommendations(): Promise<RecommendationsResponse> {
    const { data } = await client.get<RecommendationsResponse>(
      "/admin/recommendations",
    );
    return data;
  },

  async review(id: number): Promise<RecommendationReview> {
    const { data } = await client.post<RecommendationReview>(
      `/admin/recommendations/${id}/review`,
    );
    return data;
  },

  async dismiss(id: number): Promise<RecommendationReview> {
    const { data } = await client.post<RecommendationReview>(
      `/admin/recommendations/${id}/dismiss`,
    );
    return data;
  },
};
