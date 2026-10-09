import { useQuery } from "@tanstack/react-query";
import { useEffect, useRef } from "react";
import { useLocation, useNavigate, useParams } from "react-router-dom";
import { authApi } from "@/api/endpoints/auth.api";
import { ROUTES } from "@/routes/routePaths";
import { getApiErrorMessage } from "@/utils/apiErrors";
import type { RecoveryChannel, RecoveryState } from "../recovery.types";

type RecoveryStep = "find-account" | "options" | "verify" | "reset";

function readFlow(value: unknown): RecoveryState {
  if (!value || typeof value !== "object") return {};
  const input = value as Record<string, unknown>;
  return {
    username:
      typeof input.username === "string"
        ? input.username.trim().slice(0, 200)
        : undefined,
    maskedEmail:
      typeof input.maskedEmail === "string" ? input.maskedEmail : undefined,
    maskedPhoneNumber:
      typeof input.maskedPhoneNumber === "string"
        ? input.maskedPhoneNumber
        : undefined,
    channel:
      input.channel === "email" || input.channel === "sms"
        ? input.channel
        : undefined,
    resetToken:
      typeof input.resetToken === "string" && input.resetToken.trim()
        ? input.resetToken
        : undefined,
    error: typeof input.error === "string" ? input.error : undefined,
  };
}

export function usePasswordRecovery() {
  const { step: routeStep } = useParams<{ step?: string }>();
  const location = useLocation();
  const navigate = useNavigate();
  const flow = readFlow(location.state);
  const access = location.pathname.startsWith("/admin/") ? "staff" : "vendor";
  const role = access === "staff" ? "Admin" : "Vendor";
  const basePath = ROUTES.forgotPassword(access);
  const loginPath = access === "staff" ? ROUTES.adminLogin : ROUTES.login;
  const step: RecoveryStep =
    routeStep === "options" || routeStep === "verify" || routeStep === "reset"
      ? routeStep
      : "find-account";
  const headingRef = useRef<HTMLHeadingElement | null>(null);
  useEffect(() => {
    if (step !== "find-account") headingRef.current?.focus();
  }, [step]);
  const query = useQuery({
    queryKey: ["password-recovery-account", flow.username],
    queryFn: () => authApi.findAccount(flow.username ?? ""),
    enabled: step === "options" && Boolean(flow.username),
    retry: false,
    gcTime: 0,
    staleTime: 0,
    refetchOnWindowFocus: false,
  });
  const accountLookup = query.data?.found
    ? {
        maskedEmail: query.data.maskedEmail,
        maskedPhoneNumber: query.data.maskedPhoneNumber,
      }
    : null;
  const lookupError = query.isError
    ? getApiErrorMessage(
        query.error,
        "Could not find your account. Please try again.",
      )
    : query.data && !query.data.found
      ? "We could not find an account with that username."
      : "";
  const goTo = (nextStep: RecoveryStep, state: RecoveryState) =>
    navigate(`${basePath}/${nextStep}`, { state });
  return {
    flow,
    role,
    basePath,
    loginPath,
    step,
    accountLookup,
    lookupError,
    lookupLoading: query.isPending || query.isFetching,
    invalidFlow:
      (step === "options" && !flow.username) ||
      (step === "verify" && (!flow.username || !flow.channel)) ||
      (step === "reset" && (!flow.username || !flow.resetToken)),
    title: {
      "find-account": "FIND YOUR ACCOUNT",
      options: "FORGOT PASSWORD",
      verify: flow.channel === "sms" ? "CHECK YOUR SMS" : "CHECK YOUR EMAIL",
      reset: "CREATE NEW PASSWORD",
    }[step],
    stepKey: `${step}-${flow.username ?? ""}-${flow.channel ?? ""}`,
    headingRef,
    findAccount: (username: string) => goTo("options", { username }),
    selectChannel: (channel: RecoveryChannel) => {
      if (accountLookup)
        goTo("verify", { username: flow.username, ...accountLookup, channel });
    },
    tryAgain: () => goTo("find-account", { username: flow.username }),
    backToLogin: () => navigate(loginPath, { replace: true }),
    verified: (resetToken: string) =>
      goTo("reset", { username: flow.username, resetToken }),
    complete: () =>
      navigate(loginPath, { replace: true, state: { passwordReset: true } }),
  };
}
