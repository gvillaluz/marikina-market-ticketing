import { enforcersApi } from "@/api/endpoints/enforcers.api";
import { useQuery } from "@tanstack/react-query";

export function useFetchPerformance(enforcerId: number) {
  const query = useQuery({
    queryKey: ["performance", enforcerId],
    queryFn: () => enforcersApi.enforcerPerformance(enforcerId),
  });

  return {
    performance: query.data,
    performanceProcess: {
        isLoading: query.isLoading,
        isFetching: query.isFetching,
        isError: query.isError,
        error: query.error,
    }
  };
}
