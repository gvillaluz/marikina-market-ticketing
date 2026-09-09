import { enforcersApi } from "@/api/endpoints/enforcers.api";
import { EnforcerProfile } from "@/api/types/enforcer.types";
import { useQuery } from "@tanstack/react-query";

export function useFetchProfile(enforcerId: number) {
  const query = useQuery({
    queryKey: ["enforcers", enforcerId, "profile"],
    queryFn: () => enforcersApi.enforcerProfile(enforcerId),
    enabled: Number.isInteger(enforcerId) && enforcerId > 0,
    staleTime: 1000 * 60 * 5,
  });

  console.log(query.data);

  return {
    profile: query.data,
    profileProcess: {
      isLoading: query.isLoading,
      isFetching: query.isFetching,
      isError: query.isError,
      error: query.error,
    },
  };
}
