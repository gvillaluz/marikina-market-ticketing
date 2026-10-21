import { useQuery } from "@tanstack/react-query";
import { adminVendorsApi } from "@/api/endpoints/adminVendors.api";
import { getApiErrorMessage } from "@/utils/apiErrors";

export function useAdminVendorRegistrationReview(registrationId: number) {
  const detailsQuery = useQuery({
    queryKey: ["admin-vendor-registration", registrationId],
    queryFn: () => adminVendorsApi.getRegistrationDetails(registrationId),
    enabled: Number.isSafeInteger(registrationId) && registrationId > 0,
  });

  return {
    details: detailsQuery.data,
    canDecide: Boolean(
      detailsQuery.isSuccess &&
      detailsQuery.data &&
      Number.isSafeInteger(detailsQuery.data.version) &&
      detailsQuery.data.version > 0 &&
      !["approved", "rejected"].includes(
        String(detailsQuery.data.status).toLowerCase(),
      ),
    ),
    documents: detailsQuery.data?.documents ?? [],
    isLoading: detailsQuery.isLoading,
    isError: detailsQuery.isError,
    errorMessage: getApiErrorMessage(
      detailsQuery.error,
      "Unable to load the registration request.",
    ),
    refetch: async () => {
      const result = await detailsQuery.refetch();
      return result.isSuccess;
    },
  };
}
