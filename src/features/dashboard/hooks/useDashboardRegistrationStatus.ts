import { useQuery } from "@tanstack/react-query";
import { adminVendorsApi } from "@/api/endpoints/adminVendors.api";
import { useAuth } from "@/context/AuthContext";
import { getApiErrorMessage } from "@/utils/apiErrors";
import { isAdministrator } from "@/utils/roles";

export function useDashboardRegistrationStatus() {
  const { user } = useAuth();
  const enabled = isAdministrator(user?.role);
  const query = useQuery({
    queryKey: ["admin-vendor-registration-counts"],
    queryFn: adminVendorsApi.getRegistrationStatusCounts,
    enabled,
  });

  return {
    counts: query.data,
    isLoading: enabled && query.isPending,
    error: query.isError
      ? getApiErrorMessage(
          query.error,
          "We couldn't load vendor registration statuses.",
        )
      : null,
    retry: () => void query.refetch(),
  };
}
