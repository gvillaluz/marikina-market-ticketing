import axios from "axios";
import camelcaseKeys from "camelcase-keys";
import snakecaseKeys from "snakecase-keys";
import env from "@/config/env";
import type {
  AccessTokenRefreshRequest,
  TokenRefreshResponse,
} from "@/features/auth/auth.types";

export class InvalidAccessTokenError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "InvalidAccessTokenError";
  }
}

export const authRefreshApi = {
  async refreshWeb(accessToken: string): Promise<TokenRefreshResponse> {
    const request: AccessTokenRefreshRequest = { accessToken };
    const { data } = await axios.post<unknown>(
      `${env.apiBaseUrl}/api/auth/refresh-web`,
      snakecaseKeys({ accessToken: request.accessToken }),
      {
        timeout: 15000,
        headers: {
          "Content-Type": "application/json",
          "ngrok-skip-browser-warning": "true",
        },
      },
    );

    if (typeof data !== "object" || data === null) {
      throw new Error("The refresh service returned an invalid response.");
    }

    const response = camelcaseKeys(data as Record<string, unknown>, {
      deep: true,
    }) as Record<string, unknown>;

    if (
      typeof response.message === "string" &&
      /invalid access token.*log in again/i.test(response.message)
    ) {
      throw new InvalidAccessTokenError(response.message);
    }

    if (
      typeof response.accessToken !== "string" ||
      typeof response.mustChangePassword !== "boolean"
    ) {
      throw new Error("The refresh service returned incomplete token details.");
    }

    return {
      accessToken: response.accessToken,
      mustChangePassword: response.mustChangePassword,
    };
  },
};
