import { useEffect, useRef, useState } from "react";
import { useAuth } from "@/context/AuthContext";
import { useNavigate, useLocation } from "react-router-dom";
import type { LoginInput } from "@/features/auth/auth.types";
import { ROUTES } from "@/routes/routePaths";
import { getApiErrorMessage } from "@/utils/apiErrors";

export interface LoginFormValues {
  username: string;
  password: string;
}

interface UseLoginOptions {
  redirectTo?: string;
}

export function useLogin(options: UseLoginOptions = {}) {
  const busy = useRef(false);
  const { login, cancelLogin } = useAuth();
  const mounted = useRef(true);
  useEffect(() => {
    mounted.current = true;
    return () => {
      mounted.current = false;
    };
  }, []);
  const navigate = useNavigate();
  const location = useLocation();
  const [loading, setLoading] = useState(false);
  const state: unknown = location.state;
  const expired = Boolean(
    state &&
      typeof state === "object" &&
      (state as Record<string, unknown>).verificationExpired === true,
  );
  const [error, setError] = useState<string | null>(
    expired ? "Your sign-in session expired. Please sign in again." : null,
  );

  const { redirectTo } = options;
  const from =
    (location.state as { from?: { pathname: string } } | null)?.from
      ?.pathname ??
    redirectTo ??
    null;

  const submit = async (values: LoginFormValues) => {
    if (busy.current) return;
    busy.current = true;
    setLoading(true);
    setError(null);
    try {
      const input: LoginInput = {
        username: values.username.trim(),
        password: values.password,
      };

      await login(input);
      if (!mounted.current) {
        cancelLogin();
        return;
      }
      const redirectTo =
        typeof from === "string" &&
        from.startsWith("/") &&
        !from.startsWith("//") &&
        !from.includes("\\")
          ? from
          : undefined;
      navigate(ROUTES.loginVerification, {
        state: {
          redirectTo,
          access: location.pathname.startsWith("/admin/") ? "staff" : "vendor",
        },
      });
    } catch (err) {
      if (mounted.current) setError(getApiErrorMessage(err, "Login failed."));
    } finally {
      busy.current = false;
      if (mounted.current) setLoading(false);
    }
  };

  return { submit, loading, error };
}

export default useLogin;
