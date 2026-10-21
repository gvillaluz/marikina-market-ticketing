import { useQuery } from "@tanstack/react-query";
import { adminVendorsApi } from "@/api/endpoints/adminVendors.api";
import { getApiErrorMessage } from "@/utils/apiErrors";

export function useAdminVendorOverview() {
  const query = useQuery({
    queryKey: ["admin-vendor-compliance-overview"],
    queryFn: () => adminVendorsApi.getComplianceOverview(),
  });

  return {
    overview: query.data,
    isLoading: query.isLoading,
    isError: query.isError,
    errorMessage: getApiErrorMessage(query.error, "Unable to load compliance activity."),
    refetch: query.refetch,
  };
}