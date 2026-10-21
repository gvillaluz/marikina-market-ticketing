import type { AccountStatus, UserRole } from "@/api/types/common.types";

export interface UserProfileResponse {
  userId: number;
  username: string;
  firstName: string;
  middleName: string | null;
  lastName: string;
  email: string;
  dateOfBirth: string;
  phoneNumber: string;
  houseNumber: string;
  street: string;
  barangay: string;
  city: string;
  status: AccountStatus;
  role: string | number | null;
  createdAt: string;
  profileUrl: string | null;
  mustChangedPassword: boolean;
}

export interface User extends Omit<UserProfileResponse, "role"> {
  role: UserRole | null;
}

export interface LoginInput {
  username: string;
  password: string;
}

export interface RegisterInput {
  name: string;
  email: string;
  password: string;
  role: UserRole;
}

export interface AuthResponse {
  user: User;
  mustChangePassword: boolean;
  accessToken: string;
}

export interface LoginResponse {
  message: string;
  maskedEmail: string;
  resendCooldownSeconds: number;
  codeExpirySeconds: number;
}

export interface VerifyLoginInput extends LoginInput {
  code: string;
}

export interface VerifyLoginResponse {
  accessToken: string;
  mustChangePassword: boolean;
}

export interface LoginChallenge {
  maskedEmail: string;
  message: string;
  resendAvailableAt: number;
  expiresAt: number;
}

export interface AccessTokenRefreshRequest {
  accessToken: string;
}

export interface TokenRefreshResponse {
  accessToken: string;
  mustChangePassword: boolean;
}
