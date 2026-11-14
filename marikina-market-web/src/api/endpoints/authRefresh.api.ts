import axios from "axios";
import camelcaseKeys from "camelcase-keys";
import type { TokenRefreshResponse } from "@/features/auth/auth.types";

export class InvalidAccessTokenError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "InvalidAccessTokenError";
  }
}

export const authRefreshApi = {
  // The server reads the website's pass from its hidden cookie, so no pass is sent here.
  async refreshWeb(): Promise<TokenRefreshResponse> {
    const { data } = await axios.post<unknown>(
      "/api/auth/refresh-web",
      undefined,
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
