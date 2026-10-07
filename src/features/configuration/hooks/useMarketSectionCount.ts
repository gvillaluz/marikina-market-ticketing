import { adminConfigurationsApi } from "@/api/endpoints/adminConfigurations.api";
import { useQuery } from "@tanstack/react-query";

export function useMarketSectionCount() {
  const query = useQuery({
    queryKey: ["market_sections", "configurations"],
    queryFn: () => adminConfigurationsApi.marketSectionSummary(),
  });

  return {
    count: query.data?.count,
    isLoading: query.isLoading,
    isFetching: query.isFetching,
    isError: query.isError,
    error: query.error,
  };
}
