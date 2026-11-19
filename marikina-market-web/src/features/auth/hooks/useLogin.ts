import { useEffect, useRef, useState } from "react";
import { useAuth } from "@/context/AuthContext";
import { useNavigate, useLocation } from "react-router-dom";
import type { LoginInput } from "@/features/auth/auth.types";
import { ROUTES } from "@/routes/routePaths";
import { getApiErrorMessage, isConnectionError } from "@/utils/apiErrors";
import { successPause } from "../motion";

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
  const [succeeded, setSucceeded] = useState(false);
  const state: unknown = location.state;
  const expired = Boolean(
    state &&
      typeof state === "object" &&
      (state as Record<string, unknown>).verificationExpired === true,
  );
  const [error, setError] = useState<string | null>(
    expired ? "Your login session expired. Please log in again." : null,
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
      setSucceeded(true);
      await successPause();
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
      navigate(ROUTES.loginVerification, { state: { redirectTo } });
    } catch (err) {
      if (mounted.current)
        setError(
          // Same words as the phone app when the server cannot be reached.
          isConnectionError(err)
            ? "No internet connection. Please try again."
            : getApiErrorMessage(err, "Login failed."),
        );
    } finally {
      busy.current = false;
      if (mounted.current) setLoading(false);
    }
  };

  return { submit, loading, succeeded, error };
}

export default useLogin;
