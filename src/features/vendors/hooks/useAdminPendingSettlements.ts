import { useQuery } from "@tanstack/react-query";
import { adminVendorsApi } from "@/api/endpoints/adminVendors.api";
import { getApiErrorMessage } from "@/utils/apiErrors";

export function useAdminPendingSettlements(offset: number) {
  const query = useQuery({
    queryKey: ["admin-vendor-pending-settlements", offset],
    queryFn: () => adminVendorsApi.getPendingSettlements(offset),
  });

  return {
    settlements: query.data?.items ?? [],
    total: query.data?.total ?? null,
    hasMore: query.data?.hasMore ?? false,
    isLoading: query.isLoading,
    isError: query.isError,
    errorMessage: getApiErrorMessage(query.error, "Unable to load pending settlements."),
    refetch: query.refetch,
  };
}