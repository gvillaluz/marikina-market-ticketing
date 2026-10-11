import { useQuery } from "@tanstack/react-query";
import { adminVendorsApi } from "@/api/endpoints/adminVendors.api";
import { useAuth } from "@/context/AuthContext";
import { getApiErrorMessage } from "@/utils/apiErrors";
import { isAdministrator } from "@/utils/roles";

export function useRegistrationStatusCounts(poll = false) {
  const { user, isAuthenticated, isAuthReady } = useAuth();
  const enabled = isAuthReady && isAuthenticated && isAdministrator(user?.role);
  const query = useQuery({
    queryKey: ["admin-vendor-registration-counts"],
    queryFn: ({ signal }) =>
      adminVendorsApi.getRegistrationStatusCounts(signal),
    enabled,
    refetchInterval: poll && enabled ? 30_000 : false,
    refetchIntervalInBackground: false,
    refetchOnWindowFocus: poll ? "always" : false,
    refetchOnReconnect: poll ? "always" : true,
  });

  return {
    counts: enabled ? query.data : undefined,
    isLoading: enabled && query.isPending,
    error:
      enabled && query.isError
        ? getApiErrorMessage(
            query.error,
            "We couldn't load vendor registration counts. Please try again.",
          )
        : null,
    refetch: query.refetch,
    enabled,
  };
}
