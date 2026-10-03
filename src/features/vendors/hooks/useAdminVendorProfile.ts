import { useQuery } from "@tanstack/react-query";
import { adminVendorsApi } from "@/api/endpoints/adminVendors.api";
import { getApiErrorMessage } from "@/utils/apiErrors";

export function useAdminVendorProfile(vendorId: number) {
  const profileQuery = useQuery({
    queryKey: ["admin-vendor-profile", vendorId],
    queryFn: () => adminVendorsApi.getProfile(vendorId),
    enabled: Number.isInteger(vendorId) && vendorId > 0,
  });
  const scoreQuery = useQuery({
    queryKey: ["admin-vendor-compliance-score", vendorId],
    queryFn: () => adminVendorsApi.getComplianceScore(vendorId),
    enabled: Number.isInteger(vendorId) && vendorId > 0,
  });

  return {
    profile: profileQuery.data,
    score: scoreQuery.data,
    isProfileLoading: profileQuery.isLoading,
    isScoreLoading: scoreQuery.isLoading,
    isProfileError: profileQuery.isError,
    isScoreError: scoreQuery.isError,
    profileErrorMessage: getApiErrorMessage(profileQuery.error, "We couldn't load this vendor's profile."),
    scoreErrorMessage: getApiErrorMessage(scoreQuery.error, "We couldn't load this vendor's compliance score."),
    refetchProfile: profileQuery.refetch,
    refetchScore: scoreQuery.refetch,
  };
}