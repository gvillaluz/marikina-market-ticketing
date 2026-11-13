import { useQuery } from "@tanstack/react-query";
import { recommendationsApi } from "@/api/endpoints/recommendations.api";
import { getApiErrorMessage } from "@/utils/apiErrors";

export const recommendationsKey = ["admin-recommendations"];

export function useRecommendationsPage() {
  const query = useQuery({
    queryKey: recommendationsKey,
    queryFn: () => recommendationsApi.getRecommendations(),
  });
  const recommendations = query.data?.recommendations ?? [];

  return {
    data: query.data,
    openCards: recommendations.filter(
      (card) => card.review?.decision !== "Dismissed",
    ),
    dismissedCards: recommendations.filter(
      (card) => card.review?.decision === "Dismissed",
    ),
    isLoading: query.isLoading || query.isFetching,
    isError: query.isError,
    errorMessage: getApiErrorMessage(
      query.error,
      "Couldn't load recommended actions.",
    ),
    retry: () => void query.refetch(),
  };
}
