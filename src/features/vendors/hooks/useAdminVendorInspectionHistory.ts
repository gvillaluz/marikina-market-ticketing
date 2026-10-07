import { useQuery } from "@tanstack/react-query";
import { adminVendorsApi } from "@/api/endpoints/adminVendors.api";
import type { AdminVendorInspectionFilters } from "@/api/types/admin-vendor.types";
import { getApiErrorMessage } from "@/utils/apiErrors";

export function useAdminVendorInspectionHistory(
  vendorId: number,
  filters: AdminVendorInspectionFilters,
) {
  const query = useQuery({
    queryKey: ["admin-vendor-inspections", vendorId, filters],
    queryFn: () => adminVendorsApi.getInspectionHistory(vendorId, filters),
    enabled: Number.isInteger(vendorId) && vendorId > 0,
  });

  return {
    inspections: query.data?.items ?? [],
    total: query.data?.total ?? null,
    hasMore: query.data?.hasMore ?? false,
    isLoading: query.isLoading,
    isFetching: query.isFetching,
    isError: query.isError,
    errorMessage: getApiErrorMessage(query.error, "Unable to load inspection history."),
    refetch: query.refetch,
  };
}