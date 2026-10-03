import { useQuery } from "@tanstack/react-query";
import { adminVendorsApi } from "@/api/endpoints/adminVendors.api";
import type { AdminVendorSummaryFilters } from "@/api/types/admin-vendor.types";
import { getApiErrorMessage } from "@/utils/apiErrors";

const VENDOR_PAGE_SIZE = 10;

export function useAdminVendors(filters: AdminVendorSummaryFilters) {
  const query = useQuery({
    queryKey: ["admin-vendors", filters],
    queryFn: () => adminVendorsApi.list(filters),
  });

  const total = query.data?.total ?? null;
  const totalPages = total === null
    ? 1
    : Math.max(1, Math.ceil(total / VENDOR_PAGE_SIZE));

  return {
    vendors: query.data?.items ?? [],
    total,
    totalPages,
    hasMore: query.data?.hasMore ?? false,
    isLoading: query.isLoading,
    isError: query.isError,
    errorMessage: getApiErrorMessage(query.error, "Unable to load vendors. Please try again."),
    refetch: query.refetch,
  };
}
