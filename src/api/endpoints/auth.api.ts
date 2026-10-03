import client from "@/api/client";
import type {
  AuthResponse,
  LoginInput,
  LoginResponse,
  RegisterInput,
  User,
  UserProfileResponse,
} from "@/features/auth/auth.types";

export interface MandatoryChangePasswordInput {
  currentPassword: string;
  newPassword: string;
  confirmNewPassword: string;
}

export interface FindAccountResponse {
  found: boolean;
  maskedEmail: string;
  maskedPhoneNumber: string;
}

export interface SendCodeResponse {
  message?: string;
  resendCooldownSeconds: number;
  codeExpirySeconds: number;
}

export interface VerifyCodeResponse {
  success: boolean;
  message: string;
  resetToken?: string;
}

export interface ResetPasswordInput {
  username: string;
  newPassword: string;
  resetToken: string;
}

export const authApi = {
  async login(input: LoginInput): Promise<LoginResponse> {
    const { data } = await client.post<LoginResponse>("/auth/login", input);
    return data;
  },

  async register(input: RegisterInput): Promise<AuthResponse> {
    const { data } = await client.post<AuthResponse>("/auth/register", input);
    return data;
  },

  async getMe(token: string): Promise<UserProfileResponse> {
    const { data } = await client.post<UserProfileResponse>("/user/me", undefined, {
      headers: { Authorization: `Bearer ${token}` },
    });
    return data;
  },

  async logout(accessToken: string): Promise<void> {
    await client.post("/auth/logout", undefined, {
      headers: { Authorization: ["Bearer", accessToken].join(" ") },
    });
  },

  async mandatoryChangePassword(
    input: MandatoryChangePasswordInput,
  ): Promise<void> {
    await client.post("/auth/mandatory-change-password", input);
  },

  async findAccount(username: string): Promise<FindAccountResponse> {
    const { data } = await client.post<FindAccountResponse>(
      "/auth/find-account",
      { username },
    );
    return data;
  },

  async sendCode(
    username: string,
    channel: "email" | "sms",
  ): Promise<SendCodeResponse> {
    const { data } = await client.post<SendCodeResponse>("/auth/send-otp", {
      username,
      channel,
    });
    return data;
  },

  async verifyCode(username: string, code: string): Promise<VerifyCodeResponse> {
    const { data } = await client.post<VerifyCodeResponse>(
      "/auth/verify-otp",
      { username, code },
    );
    return data;
  },

  async resetPassword(input: ResetPasswordInput): Promise<void> {
    await client.post("/auth/reset-password", input);
  },
};
