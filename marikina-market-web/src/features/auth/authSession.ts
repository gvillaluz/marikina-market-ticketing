import axios, { AxiosError } from "axios";
import { jwtDecode } from "jwt-decode";
import type { TokenRefreshResponse } from "./auth.types";
import { useAuthStore } from "@/store/store";
import {
  authRefreshApi,
  InvalidAccessTokenError,
} from "@/api/endpoints/authRefresh.api";

const AUTH_SESSION_KEY = "marikina-auth-session";

interface StoredAuthSession {
  accessToken: string;
}

export class RefreshSessionExpiredError extends Error {
  constructor(
    message = "Your session has expired. Please sign in again.",
    readonly sessionVersion?: number,
  ) {
    super(message);
    this.name = "RefreshSessionExpiredError";
  }
}

let sessionVersion = 0;
let authSession: StoredAuthSession | null = null;
let refreshRequest: {
  version: number;
  promise: Promise<TokenRefreshResponse>;
} | null = null;

export function storeAuthSession(accessToken: string): void {
  if (!accessToken || !getAccessTokenExpiration(accessToken)) {
    throw new Error("The server returned an invalid access token.");
  }

  const session: StoredAuthSession = { accessToken };
  authSession = session;
  sessionVersion += 1;
}

export function getStoredAuthSession(): StoredAuthSession | null {
  sessionStorage.removeItem(AUTH_SESSION_KEY);
  return authSession ? { ...authSession } : null;
}

export function clearAuthSession(): void {
  authSession = null;
  sessionStorage.removeItem(AUTH_SESSION_KEY);
  sessionVersion += 1;
}

export function getAccessTokenExpiration(accessToken: string): number | null {
  try {
    const claims = jwtDecode<{ exp?: number }>(accessToken);
    return typeof claims.exp === "number" && Number.isFinite(claims.exp)
      ? claims.exp * 1000
      : null;
  } catch {
    return null;
  }
}

export function invalidateAuthSession(expectedVersion?: number): void {
  if (expectedVersion !== undefined && expectedVersion !== sessionVersion)
    return;
  clearAuthSession();
  useAuthStore.getState().logout();
}

export function getAuthSessionVersion(): number {
  return sessionVersion;
}

export function refreshAccessToken(): Promise<TokenRefreshResponse> {
  if (!getStoredAuthSession()) {
    throw new RefreshSessionExpiredError(undefined, sessionVersion);
  }
  return requestRefresh();
}

// After a page refresh the page has no pass in memory; the server signs the
// user back in from its hidden cookie.
export function restoreAuthSession(): Promise<TokenRefreshResponse> {
  return requestRefresh();
}

function requestRefresh(): Promise<TokenRefreshResponse> {
  if (refreshRequest?.version === sessionVersion) return refreshRequest.promise;

  const requestVersion = sessionVersion;
  const currentToken = getStoredAuthSession()?.accessToken ?? null;
  const promise = requestWebAccessToken(currentToken, requestVersion).finally(
    () => {
      if (refreshRequest?.promise === promise) refreshRequest = null;
    },
  );
  refreshRequest = { version: requestVersion, promise };
  return promise;
}

async function requestWebAccessToken(
  expectedToken: string | null,
  requestVersion: number,
): Promise<TokenRefreshResponse> {
  try {
    const refreshed = await authRefreshApi.refreshWeb();
    const accessTokenExpiration = getAccessTokenExpiration(
      refreshed.accessToken,
    );
    if (!accessTokenExpiration || accessTokenExpiration <= Date.now()) {
      throw new Error("The refresh service returned an invalid access token.");
    }
    if (
      requestVersion !== sessionVersion ||
      (getStoredAuthSession()?.accessToken ?? null) !== expectedToken
    ) {
      throw new RefreshSessionExpiredError(
        "The session changed while refreshing. Please try again.",
        requestVersion,
      );
    }

    const updatedSession: StoredAuthSession = {
      accessToken: refreshed.accessToken,
    };
    authSession = updatedSession;
    useAuthStore.getState().setAccessToken(refreshed.accessToken);
    useAuthStore.getState().setMustChangePassword(refreshed.mustChangePassword);
    return refreshed;
  } catch (error) {
    if (error instanceof RefreshSessionExpiredError) throw error;
    if (error instanceof InvalidAccessTokenError) {
      throw new RefreshSessionExpiredError(error.message, requestVersion);
    }
    if (axios.isAxiosError(error) && isRejectedRefreshRequest(error)) {
      throw new RefreshSessionExpiredError(undefined, requestVersion);
    }
    throw error;
  }
}

function isRejectedRefreshRequest(error: AxiosError): boolean {
  const status = error.response?.status;
  return status === 400 || status === 401 || status === 403;
}
