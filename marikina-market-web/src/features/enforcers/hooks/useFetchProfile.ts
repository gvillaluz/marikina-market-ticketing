import { enforcersApi } from "@/api/endpoints/enforcers.api";
import { EnforcerProfile } from "@/api/types/enforcer.types";
import { getApiErrorMessage } from "@/utils/apiErrors";
import { useQuery } from "@tanstack/react-query";

export function useFetchProfile(enforcerId: number) {
  const query = useQuery({
    queryKey: ["enforcers", enforcerId, "profile"],
    queryFn: () => enforcersApi.enforcerProfile(enforcerId),
    enabled: Number.isInteger(enforcerId) && enforcerId > 0,
    staleTime: 1000 * 60 * 5,
  });

  return {
    profile: query.data,
    profileProcess: {
      isLoading: query.isLoading,
      isFetching: query.isFetching,
      isError: query.isError,
      errorMessage: getApiErrorMessage(
        query.error,
        "Couldn't load the enforcer's profile.",
      ),
      onRetry: query.refetch,
    },
  };
}
