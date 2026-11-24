import client from "@/api/client";
import type { PaginatedResponse } from "@/api/types/common.types";
import type {
  DetectedViolation,
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

  async getDetectedViolations(
    offset: number,
  ): Promise<PaginatedResponse<DetectedViolation>> {
    const { data } = await client.get<PaginatedResponse<DetectedViolation>>(
      "/admin/recommendations/findings",
      { params: { offset } },
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
