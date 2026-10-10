import { useQuery } from "@tanstack/react-query";
import { profileApi, type ProfileResponse } from "@/api/endpoints/profile.api";
import { useAuth } from "@/context/AuthContext";
import { ApiRequestError, getApiErrorMessage } from "@/utils/apiErrors";
import { normalizeUserRole } from "@/utils/roles";

export function validateProfile(profile: ProfileResponse): void {
  if (
    !profile ||
    !Number.isSafeInteger(profile.userId) ||
    profile.userId <= 0 ||
    ![
      profile.username,
      profile.firstName,
      profile.lastName,
      profile.dateOfBirth,
      profile.email,
      profile.phoneNumber,
      profile.houseNumber,
      profile.street,
      profile.barangay,
      profile.city,
      profile.createdAt,
    ].every((value) => typeof value === "string") ||
    ![profile.middleName, profile.profileUrl].every(
      (value) => value === null || typeof value === "string",
    ) ||
    !["Active", "Inactive"].includes(profile.status) ||
    typeof profile.mustChangedPassword !== "boolean"
  ) {
    throw new ApiRequestError();
  }
}

export function useProfile() {
  const { user } = useAuth();
  const query = useQuery({
    queryKey: ["profile", user?.userId],
    enabled: Boolean(user),
    gcTime: 0,
    retry: false,
    queryFn: async ({ signal }) => {
      const profile = await profileApi.getMe(signal);
      if (profile === null) return null;
      validateProfile(profile);
      try {
        return { ...profile, role: normalizeUserRole(profile.role) };
      } catch {
        throw new ApiRequestError();
      }
    },
  });

  return {
    profile: query.data,
    isLoading: query.isPending,
    isRetrying: query.isFetching,
    error: query.isError
      ? getApiErrorMessage(
          query.error instanceof ApiRequestError ? query.error : undefined,
          "Unable to load your profile. Please try again.",
        )
      : null,
    retry: () => void query.refetch(),
  };
}
