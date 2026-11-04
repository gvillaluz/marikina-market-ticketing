import { adminConfigurationsApi } from "@/api/endpoints/adminConfigurations.api";
import { useQuery } from "@tanstack/react-query";
import { getApiErrorMessage } from "@/utils/apiErrors";

export function useMarketSectionCount() {
  const query = useQuery({
    queryKey: ["market_sections", "configurations"],
    queryFn: () => adminConfigurationsApi.marketSectionSummary(),
  });

  return {
    count: query.data?.count,
    isLoading: query.isPending,
    isFetching: query.isFetching,
    error: query.isError
      ? getApiErrorMessage(
          query.error,
          "Unable to load market sections. Please try again.",
        )
      : "",
    retry: () => {
      void query.refetch();
    },
  };
}
