import client from "@/api/client";
import type { UserProfileResponse } from "@/features/auth/auth.types";

export type ProfileResponse = UserProfileResponse;

export interface ProfileUpdateInput {
  firstName: string;
  middleName: string | null;
  lastName: string;
  dateOfBirth: string;
  email: string;
  phoneNumber: string;
  houseNumber: string;
  street: string;
  barangay: string;
  city: string;
}

export const profileApi = {
  async update(input: ProfileUpdateInput): Promise<ProfileResponse> {
    const { data } = await client.post<ProfileResponse>("/user/profile", input);
    return data;
  },
  async getMe(signal?: AbortSignal): Promise<ProfileResponse | null> {
    const { data } = await client.post<ProfileResponse | null>(
      "/user/me",
      undefined,
      { signal },
    );
    return data;
  },
};
