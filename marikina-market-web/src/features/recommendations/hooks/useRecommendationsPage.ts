import { useQuery } from "@tanstack/react-query";
import { recommendationsApi } from "@/api/endpoints/recommendations.api";
import { getApiErrorMessage } from "@/utils/apiErrors";

export function useRecommendationsPage() {
  const query = useQuery({
    queryKey: ["admin-recommendations"],
    queryFn: () => recommendationsApi.getRecommendations(),
  });

  return {
    data: query.data,
    isLoading: query.isLoading || query.isFetching,
    isError: query.isError,
    errorMessage: getApiErrorMessage(
      query.error,
      "Couldn't load recommended actions.",
    ),
    retry: () => void query.refetch(),
  };
}
