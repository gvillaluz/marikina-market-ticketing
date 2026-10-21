import { useEffect, useRef, useState, type FormEvent } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { useAuth } from "@/context/AuthContext";
import { STAFF_ROLES, type UserRole } from "@/api/types/common.types";
import { ROUTES } from "@/routes/routePaths";
import { roleHomePath } from "@/utils/roles";
import { getApiErrorMessage } from "@/utils/apiErrors";
import { useOtpInput } from "./useOtpInput";

function timerLabel(seconds: number) {
  return `${String(Math.floor(seconds / 60)).padStart(2, "0")}:${String(seconds % 60).padStart(2, "0")}`;
}

export function useTwoFactorLogin() {
  const {
    loginChallenge,
    verifyLogin,
    resendLogin,
    cancelLogin,
    isAuthenticated,
    user,
    mustChangePassword,
  } = useAuth();
  const location = useLocation();
  const navigate = useNavigate();
  const state: unknown = location.state;
  const routeState =
    state && typeof state === "object"
      ? (state as Record<string, unknown>)
      : {};
  const access = routeState.access === "staff" ? "staff" : "vendor";
  const loginPath = access === "staff" ? ROUTES.adminLogin : ROUTES.login;
  const requestedPath = routeState.redirectTo;
  const redirectTo =
    typeof requestedPath === "string" &&
    requestedPath.startsWith("/") &&
    !requestedPath.startsWith("//") &&
    !requestedPath.includes("\\") &&
    ![ROUTES.login, ROUTES.adminLogin, ROUTES.loginVerification].some(
      (path) => path === requestedPath,
    )
      ? requestedPath
      : undefined;
  const [now, setNow] = useState(Date.now());
  const [verifying, setVerifying] = useState(false);
  const [resending, setResending] = useState(false);
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");
  const busy = useRef(false);
  const mounted = useRef(false);
  useEffect(() => {
    mounted.current = true;
    return () => {
      mounted.current = false;
    };
  }, []);
  useEffect(() => {
    const timer = window.setInterval(() => setNow(Date.now()), 1000);
    return () => window.clearInterval(timer);
  }, []);
  const remaining = Math.max(
    0,
    Math.ceil(((loginChallenge?.expiresAt ?? 0) - now) / 1000),
  );
  const cooldown = Math.max(
    0,
    Math.ceil(((loginChallenge?.resendAvailableAt ?? 0) - now) / 1000),
  );
  const expired = remaining === 0;
  const otp = useOtpInput(
    verifying || resending || expired,
    loginChallenge?.expiresAt,
  );
  function destination(role: UserRole | null | undefined, mustChange: boolean) {
    if (!role) return loginPath;
    if (mustChange && STAFF_ROLES.includes(role)) return ROUTES.changePassword;
    return redirectTo ?? roleHomePath(role);
  }
  return {
    loginChallenge,
    access,
    loginPath,
    isAuthenticated,
    authenticatedPath: destination(user?.role, mustChangePassword),
    otp,
    verifying,
    resending,
    error,
    notice,
    expired,
    cooldownLabel: timerLabel(cooldown),
    resendLabel:
      cooldown > 0 ? `Resend in ${timerLabel(cooldown)}` : "Resend code",
    canResend:
      Boolean(loginChallenge) && !verifying && !resending && cooldown === 0,
    canVerify: Boolean(loginChallenge) && !verifying && !resending && !expired,
    cancel() {
      cancelLogin();
      navigate(loginPath, { replace: true });
    },
    async resend() {
      if (
        busy.current ||
        !loginChallenge ||
        Date.now() < loginChallenge.resendAvailableAt
      )
        return;
      busy.current = true;
      setResending(true);
      setError("");
      setNotice("");
      try {
        const challenge = await resendLogin();
        if (!mounted.current) return;
        setNow(Date.now());
        otp.reset();
        setNotice(challenge.message);
      } catch (failure) {
        if (mounted.current)
          setError(
            getApiErrorMessage(
              failure,
              "Unable to resend the sign-in code. Please try again.",
            ),
          );
      } finally {
        busy.current = false;
        if (mounted.current) setResending(false);
      }
    },
    async verify(event: FormEvent<HTMLFormElement>) {
      event.preventDefault();
      if (
        busy.current ||
        !loginChallenge ||
        Date.now() >= loginChallenge.expiresAt
      )
        return;
      setError("");
      setNotice("");
      const code = otp.code.join("");
      if (!/^\d{6}$/.test(code)) {
        setError("Enter a 6-digit code.");
        otp.focusFirst();
        return;
      }
      busy.current = true;
      setVerifying(true);
      try {
        const result = await verifyLogin(code);
        if (mounted.current)
          navigate(destination(result.user.role, result.mustChangePassword), {
            replace: true,
          });
      } catch (failure) {
        if (mounted.current)
          setError(
            getApiErrorMessage(
              failure,
              "Unable to verify the sign-in code. Please try again.",
            ),
          );
      } finally {
        busy.current = false;
        if (mounted.current) setVerifying(false);
      }
    },
  };
}
