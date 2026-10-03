import { useQuery } from "@tanstack/react-query";
import { useState } from "react";
import { adminVendorsApi } from "@/api/endpoints/adminVendors.api";
import { getApiErrorMessage } from "@/utils/apiErrors";

const PAGE_SIZE = 10;

export function useAdminVendorRegistrations() {
  const [page, setPage] = useState(1);
  const [status, setStatus] = useState("all");
  const [vendorType, setVendorType] = useState("all");

  const countsQuery = useQuery({
    queryKey: ["admin-vendor-registration-counts"],
    queryFn: () => adminVendorsApi.getRegistrationStatusCounts(),
  });
  const requestsQuery = useQuery({
    queryKey: ["admin-vendor-registrations", page, status, vendorType],
    queryFn: () =>
      adminVendorsApi.getRegistrationRequests({
        offset: (page - 1) * PAGE_SIZE,
        status: status === "all" ? undefined : status,
        vendorType: vendorType === "all" ? undefined : vendorType,
      }),
  });

  const total = requestsQuery.data?.total ?? null;

  return {
    page,
    setPage,
    status,
    setStatus: (value: string) => {
      setStatus(value);
      setPage(1);
    },
    vendorType,
    setVendorType: (value: string) => {
      setVendorType(value);
      setPage(1);
    },
    total,
    totalPages:
      total === null
        ? page + (requestsQuery.data?.hasMore ? 1 : 0)
        : Math.max(1, Math.ceil(total / PAGE_SIZE)),
    counts: countsQuery.data,
    registrations: requestsQuery.data?.items ?? [],
    hasMore: requestsQuery.data?.hasMore ?? false,
    isLoading: requestsQuery.isLoading,
    isError: requestsQuery.isError,
    errorMessage: getApiErrorMessage(
      requestsQuery.error,
      "Unable to load vendor registration requests.",
    ),
    isCountsLoading: countsQuery.isLoading,
    refetch: requestsQuery.refetch,
  };
}
