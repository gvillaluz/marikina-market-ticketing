import { enforcersApi } from "@/api/endpoints/enforcers.api";
import { useQuery } from "@tanstack/react-query";
import { getApiErrorMessage } from "@/utils/apiErrors";

export function useFetchPerformance(enforcerId: number) {
  const query = useQuery({
    queryKey: ["performance", enforcerId],
    queryFn: () => enforcersApi.enforcerPerformance(enforcerId),
    enabled: Number.isInteger(enforcerId) && enforcerId > 0,
  });

  return {
    performance: query.data,
    performanceProcess: {
      isLoading: query.isLoading,
      isFetching: query.isFetching,
      isError: query.isError,
      errorMessage: getApiErrorMessage(
        query.error,
        "Couldn't load the performance summary.",
      ),
      onRetry: query.refetch,
    },
  };
}
