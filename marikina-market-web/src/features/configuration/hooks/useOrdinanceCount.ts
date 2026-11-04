import { adminConfigurationsApi } from "@/api/endpoints/adminConfigurations.api";
import { useQuery } from "@tanstack/react-query";
import { getApiErrorMessage } from "@/utils/apiErrors";

export function useOrdinanceCount() {
  const query = useQuery({
    queryKey: ["ordinance", "configurations", "count"],
    queryFn: () => adminConfigurationsApi.ordinanceSummary(),
  });

  return {
    count: query.data?.count,
    isLoading: query.isPending,
    isFetching: query.isFetching,
    error: query.isError
      ? getApiErrorMessage(
          query.error,
          "Unable to load active ordinances. Please try again.",
        )
      : "",
    retry: () => {
      void query.refetch();
    },
  };
}
