import axios, {
  AxiosError,
  AxiosInstance,
  InternalAxiosRequestConfig,
} from "axios";
import env from "@/config/env";
import { useAuthStore } from "@/store/store";
import snakecaseKeys from "snakecase-keys";
import camelcaseKeys from "camelcase-keys";
import {
  getAuthSessionVersion,
  invalidateAuthSession,
  refreshAccessToken,
  RefreshSessionExpiredError,
} from "@/features/auth/authSession";
import { ApiRequestError, getApiResponseMessage } from "@/utils/apiErrors";

type RetriableRequestConfig = InternalAxiosRequestConfig & {
  authRetry?: boolean;
  authSessionVersion?: number;
};

const PUBLIC_AUTH_PATHS = [
  "/auth/login",
  "/auth/verify-login",
  "/auth/register",
  "/auth/logout",
  "/auth/find-account",
  "/auth/send-otp",
  "/auth/verify-otp",
  "/auth/reset-password",
  "/auth/refresh-web",
  "/vendor/register",
];

function isPublicAuthRequest(url?: string): boolean {
  return Boolean(url && PUBLIC_AUTH_PATHS.some((path) => url.includes(path)));
}

const client: AxiosInstance = axios.create({
  baseURL: `${env.apiBaseUrl}/api`,
  timeout: 15000,
  headers: {
    "Content-Type": "application/json",
    "ngrok-skip-browser-warning": "true",
  },
});

client.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    const token = useAuthStore.getState().token;
    if (
      token &&
      !config.headers.Authorization &&
      !isPublicAuthRequest(config.url)
    ) {
      config.headers.Authorization = `Bearer ${token}`;
    }

    if (
      (token || config.headers.Authorization) &&
      !isPublicAuthRequest(config.url)
    ) {
      (config as RetriableRequestConfig).authSessionVersion =
        getAuthSessionVersion();
    }

    if (
      config.data &&
      typeof config.data === "object" &&
      !(config.data instanceof FormData)
    ) {
      config.data = snakecaseKeys(config.data, { deep: true });
    }

    if (config.params && typeof config.params === "object") {
      config.params = snakecaseKeys(config.params, { deep: true });
    }
    return config;
  },
  (error) => Promise.reject(error),
);

client.interceptors.response.use(
  (response) => {
    const isBinaryData =
      (typeof Blob !== "undefined" && response.data instanceof Blob) ||
      response.data instanceof ArrayBuffer;
    if (response.data && typeof response.data === "object" && !isBinaryData) {
      response.data = camelcaseKeys(response.data, { deep: true });
    }

    return response;
  },
  async (error: AxiosError) => {
    const request = error.config as RetriableRequestConfig | undefined;
    const isAuthenticatedRequest = request && !isPublicAuthRequest(request.url);
    const apiMessage = getApiResponseMessage(error.response?.data);
    const apiError = new ApiRequestError(apiMessage);

    if (error.response?.status === 401 && isAuthenticatedRequest) {
      const requestVersion = request.authSessionVersion;
      if (
        requestVersion !== undefined &&
        requestVersion !== getAuthSessionVersion()
      ) {
        return Promise.reject(apiError);
      }
      if (request.authRetry) {
        invalidateAuthSession(requestVersion);
      } else {
        request.authRetry = true;
        const currentToken = useAuthStore.getState().token;
        const currentAuthorization = currentToken
          ? ["Bearer", currentToken].join(" ")
          : null;
        if (
          currentAuthorization &&
          request.headers.Authorization !== currentAuthorization
        ) {
          request.headers.Authorization = currentAuthorization;
          return client.request(request);
        }
        try {
          const refreshed = await refreshAccessToken();
          request.headers.Authorization = [
            "Bearer",
            refreshed.accessToken,
          ].join(" ");
          return client.request(request);
        } catch (refreshError) {
          if (refreshError instanceof RefreshSessionExpiredError) {
            invalidateAuthSession(refreshError.sessionVersion);
          }
          return Promise.reject(refreshError);
        }
      }
    }
    return Promise.reject(apiError);
  },
);

export default client;
