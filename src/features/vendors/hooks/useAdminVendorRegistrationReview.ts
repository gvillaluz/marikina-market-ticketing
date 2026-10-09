import { useQuery } from "@tanstack/react-query";
import { adminVendorsApi } from "@/api/endpoints/adminVendors.api";
import { getApiErrorMessage } from "@/utils/apiErrors";

export function useAdminVendorRegistrationReview(registrationId: number) {
  const detailsQuery = useQuery({
    queryKey: ["admin-vendor-registration", registrationId],
    queryFn: () => adminVendorsApi.getRegistrationDetails(registrationId),
    enabled: Number.isSafeInteger(registrationId) && registrationId > 0,
  });

  const documentsQuery = useQuery({
    queryKey: ["admin-vendor-registration-documents", registrationId],
    queryFn: () => adminVendorsApi.getRegistrationDocuments(registrationId),
    enabled:
      Number.isSafeInteger(registrationId) &&
      registrationId > 0 &&
      detailsQuery.isSuccess &&
      !String(detailsQuery.data?.status ?? "")
        .toLowerCase()
        .includes("approve"),
  });

  return {
    details: detailsQuery.data,
    canDecide: Boolean(
      detailsQuery.data &&
        !["approved", "rejected"].includes(
          String(detailsQuery.data.status).toLowerCase(),
        ),
    ),
    documents: documentsQuery.data ?? [],
    isLoading: detailsQuery.isLoading || documentsQuery.isLoading,
    isError: detailsQuery.isError || documentsQuery.isError,
    errorMessage: getApiErrorMessage(
      detailsQuery.error ?? documentsQuery.error,
      "Unable to load the registration request.",
    ),
    refetch: async () => {
      await Promise.all([detailsQuery.refetch(), documentsQuery.refetch()]);
    },
  };
}
