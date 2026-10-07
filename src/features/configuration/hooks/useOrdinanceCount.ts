import { adminConfigurationsApi } from "@/api/endpoints/adminConfigurations.api";
import { useQuery } from "@tanstack/react-query";

export function useOrdinanceCount() {
  const query = useQuery({
    queryKey: ["ordinance", "configurations", "count"],
    queryFn: () => adminConfigurationsApi.ordinanceSummary(),
  });

  return {
    count: query.data?.count,
    isLoading: query.isLoading,
    isFetching: query.isFetching,
    isError: query.isError,
    error: query.error,
  };
}
