import { useLoginChallenge } from "@/features/auth/hooks/useLoginChallenge";
import {
  createContext,
  ReactNode,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
} from "react";
import axios from "axios";
import { useAuthStore } from "@/store/store";
import { getApiErrorMessage } from "@/utils/apiErrors";
import { useToast } from "@/components/ui/Toast/useToast";
import type {
  User,
  LoginInput,
  LoginChallenge,
  RegisterInput,
} from "@/features/auth/auth.types";
import { authApi } from "@/api/endpoints/auth.api";
import {
  isAdministrator,
  normalizeUserRole,
  UnsupportedUserRoleError,
} from "@/utils/roles";
import {
  clearAuthSession,
  getAuthSessionVersion,
  getAccessTokenExpiration,
  getStoredAuthSession,
  invalidateAuthSession,
  refreshAccessToken,
  RefreshSessionExpiredError,
  storeAuthSession,
} from "@/features/auth/authSession";

const REFRESH_BUFFER_MS = 60_000;
const REFRESH_RETRY_MS = 10_000;

function isAuthenticationFailure(error: unknown): boolean {
  if (error instanceof UnsupportedUserRoleError) return true;
  if (error instanceof RefreshSessionExpiredError) return true;
  if (!axios.isAxiosError(error)) return false;
  const status = error.response?.status;
  return status === 400 || status === 401 || status === 403;
}

interface AuthContextValue {
  user: User | null;
  isAuthenticated: boolean;
  isAuthReady: boolean;
  isAdmin: boolean;
  isVendor: boolean;
  mustChangePassword: boolean;
  login: (input: LoginInput) => Promise<LoginChallenge>;
  loginChallenge: LoginChallenge | null;
  verifyLogin: (
    code: string,
  ) => Promise<{ user: User; mustChangePassword: boolean }>;
  resendLogin: () => Promise<LoginChallenge>;
  cancelLogin: () => void;
  register: (input: RegisterInput) => Promise<void>;
  logout: () => void;
  clearMustChangePassword: () => void;
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const {
    user,
    token,
    isAuthenticated,
    mustChangePassword,
    setAuth,
    setMustChangePassword,
  } = useAuthStore();
  const { showToast } = useToast();
  const [isAuthReady, setIsAuthReady] = useState(false);
  const refreshWarningShown = useRef(false);

  const completeLogin = useCallback(
    (authenticatedUser: User, accessToken: string, mustChange: boolean) => {
      clearAuthSession();
      storeAuthSession(accessToken);
      setAuth(authenticatedUser, accessToken);
      setMustChangePassword(mustChange);
      setIsAuthReady(true);
    },
    [setAuth, setMustChangePassword],
  );
  const challengeReady = useCallback(() => setIsAuthReady(true), []);
  const { login, loginChallenge, verifyLogin, resendLogin, cancelLogin } =
    useLoginChallenge(completeLogin, challengeReady);

  const register = useCallback(
    async (input: RegisterInput) => {
      const response = await authApi.register(input);
      const accessTokenExpiration = getAccessTokenExpiration(
        response.accessToken,
      );
      if (!accessTokenExpiration || accessTokenExpiration <= Date.now()) {
        throw new Error("The server returned an invalid access token.");
      }

      clearAuthSession();
      storeAuthSession(response.accessToken);

      try {
        const profile = await authApi.getMe(response.accessToken);
        const authenticatedUser: User = {
          ...profile,
          role: normalizeUserRole(profile.role),
        };
        setAuth(authenticatedUser, response.accessToken);
        setMustChangePassword(
          profile.mustChangedPassword || response.mustChangePassword,
        );
        setIsAuthReady(true);
      } catch (error) {
        clearAuthSession();
        throw error;
      }
    },
    [setAuth, setMustChangePassword],
  );

  const logout = useCallback(() => {
    cancelLogin();
    const accessToken = useAuthStore.getState().token;
    invalidateAuthSession();
    if (accessToken) {
      void authApi.logout(accessToken).catch((error: unknown) => {
        console.warn(
          "The server could not invalidate the signed-out session.",
          getApiErrorMessage(error, "Unknown logout error."),
        );
      });
    }
  }, [cancelLogin]);

  const clearMustChangePassword = useCallback(() => {
    setMustChangePassword(false);
  }, [setMustChangePassword]);

  useEffect(() => {
    localStorage.removeItem("marikina-auth");

    let isCancelled = false;
    let retryTimer: number | undefined;
    const restoreSession = async () => {
      const restoreVersion = getAuthSessionVersion();
      const storedSession = getStoredAuthSession();
      if (!storedSession) {
        setIsAuthReady(true);
        return;
      }

      try {
        const refreshed = await refreshAccessToken();
        const profile = await authApi.getMe(refreshed.accessToken);
        if (isCancelled || restoreVersion !== getAuthSessionVersion()) return;

        const restoredUser: User = {
          ...profile,
          role: normalizeUserRole(profile.role),
        };
        setAuth(restoredUser, refreshed.accessToken);
        setMustChangePassword(
          profile.mustChangedPassword || refreshed.mustChangePassword,
        );
        refreshWarningShown.current = false;
        setIsAuthReady(true);
      } catch (error) {
        if (isCancelled || restoreVersion !== getAuthSessionVersion()) return;

        const latestSession = getStoredAuthSession();
        if (isAuthenticationFailure(error) || !latestSession) {
          invalidateAuthSession(restoreVersion);
          setIsAuthReady(true);
          return;
        }

        retryTimer = window.setTimeout(
          () => void restoreSession(),
          REFRESH_RETRY_MS,
        );
        if (!refreshWarningShown.current) {
          refreshWarningShown.current = true;
          showToast({
            title: "Session restoration delayed",
            description:
              "The connection to the authentication service failed. We will retry automatically.",
            variant: "warning",
          });
        }
      }
    };

    void restoreSession();
    return () => {
      isCancelled = true;
      if (retryTimer !== undefined) window.clearTimeout(retryTimer);
    };
  }, [setAuth, setMustChangePassword, showToast]);

  useEffect(() => {
    if (!isAuthReady || !isAuthenticated || !token) return;

    const session = getStoredAuthSession();
    const authSessionVersion = getAuthSessionVersion();
    const accessTokenExpiration = getAccessTokenExpiration(token);
    if (!session || !accessTokenExpiration) {
      if (session) invalidateAuthSession(authSessionVersion);
      return;
    }

    let retryTimer: number | undefined;
    let refreshTimer: number | undefined;
    const refreshBeforeExpiry = async () => {
      if (authSessionVersion !== getAuthSessionVersion()) return;
      const latestSession = getStoredAuthSession();
      if (!latestSession) {
        invalidateAuthSession(authSessionVersion);
        return;
      }

      try {
        const refreshed = await refreshAccessToken();
        if (authSessionVersion !== getAuthSessionVersion()) return;
        setMustChangePassword(refreshed.mustChangePassword);
        refreshWarningShown.current = false;
      } catch (error) {
        if (
          error instanceof RefreshSessionExpiredError &&
          error.sessionVersion !== getAuthSessionVersion()
        ) {
          return;
        }
        if (authSessionVersion !== getAuthSessionVersion()) return;
        const updatedSession = getStoredAuthSession();
        if (isAuthenticationFailure(error) || !updatedSession) {
          invalidateAuthSession(
            error instanceof RefreshSessionExpiredError
              ? error.sessionVersion
              : authSessionVersion,
          );
          return;
        }

        retryTimer = window.setTimeout(
          () => void refreshBeforeExpiry(),
          REFRESH_RETRY_MS,
        );
        if (!refreshWarningShown.current) {
          refreshWarningShown.current = true;
          showToast({
            title: "Session refresh delayed",
            description:
              "Your session is still active. We will retry refreshing it automatically.",
            variant: "warning",
          });
        }
      }
    };

    const lifetime = accessTokenExpiration - Date.now();
    const buffer = Math.min(REFRESH_BUFFER_MS, Math.max(5_000, lifetime * 0.1));
    const refreshAt = accessTokenExpiration - buffer;
    refreshTimer = window.setTimeout(
      () => void refreshBeforeExpiry(),
      Math.max(0, refreshAt - Date.now()),
    );
    return () => {
      if (refreshTimer !== undefined) window.clearTimeout(refreshTimer);
      if (retryTimer !== undefined) window.clearTimeout(retryTimer);
    };
  }, [isAuthReady, isAuthenticated, token, setMustChangePassword, showToast]);

  const value = useMemo<AuthContextValue>(
    () => ({
      user,
      isAuthenticated,
      isAuthReady,
      isAdmin: isAdministrator(user?.role),
      isVendor: user?.role === "MarketVendor",
      mustChangePassword,
      login,
      loginChallenge,
      verifyLogin,
      resendLogin,
      cancelLogin,
      register,
      logout,
      clearMustChangePassword,
    }),
    [
      user,
      isAuthenticated,
      isAuthReady,
      mustChangePassword,
      login,
      loginChallenge,
      verifyLogin,
      resendLogin,
      cancelLogin,
      register,
      logout,
      clearMustChangePassword,
    ],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const context = useContext(AuthContext);
  if (!context) throw new Error("useAuth must be used within an AuthProvider.");
  return context;
}

export default AuthContext;
