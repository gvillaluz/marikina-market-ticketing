import { useCallback, useEffect, useRef, useState } from "react";
import { useLocation } from "react-router-dom";
import { authApi } from "@/api/endpoints/auth.api";
import { ROUTES } from "@/routes/routePaths";
import { ApiRequestError } from "@/utils/apiErrors";
import { normalizeUserRole } from "@/utils/roles";
import { clearAuthSession, getAccessTokenExpiration } from "../authSession";
import type {
  LoginChallenge,
  LoginInput,
  LoginResponse,
  User,
} from "../auth.types";

interface PendingLogin {
  credentials: LoginInput;
  challenge: LoginChallenge;
}

function challengeFrom(response: LoginResponse): LoginChallenge {
  if (
    !response ||
    typeof response.maskedEmail !== "string" ||
    !response.maskedEmail.trim() ||
    typeof response.message !== "string" ||
    ![response.resendCooldownSeconds, response.codeExpirySeconds].every(
      (value) => Number.isSafeInteger(value) && value >= 0 && value <= 86400,
    )
  )
    throw new ApiRequestError(
      "Unable to start sign-in verification. Please try again.",
    );
  const now = Date.now();
  return {
    maskedEmail: response.maskedEmail,
    message: response.message,
    resendAvailableAt: now + response.resendCooldownSeconds * 1000,
    expiresAt: now + response.codeExpirySeconds * 1000,
  };
}

export function useLoginChallenge(
  onAuthenticated: (
    user: User,
    token: string,
    mustChangePassword: boolean,
  ) => void,
  onChallenge: () => void,
) {
  const [loginChallenge, setLoginChallenge] = useState<LoginChallenge | null>(
    null,
  );
  const pending = useRef<PendingLogin | null>(null);
  const generation = useRef(0);
  const busy = useRef(false);
  const location = useLocation();
  const previousPath = useRef(location.pathname);
  const cancelLogin = useCallback(() => {
    generation.current += 1;
    pending.current = null;
    setLoginChallenge(null);
  }, []);
  useEffect(() => {
    const leftLogin =
      [ROUTES.login, ROUTES.adminLogin].some(
        (path) => path === previousPath.current,
      ) &&
      location.pathname !== previousPath.current &&
      location.pathname !== ROUTES.loginVerification;
    if (
      leftLogin ||
      (previousPath.current === ROUTES.loginVerification &&
        location.pathname !== ROUTES.loginVerification)
    )
      cancelLogin();
    previousPath.current = location.pathname;
  }, [location.pathname, cancelLogin]);
  useEffect(
    () => () => {
      generation.current += 1;
      pending.current = null;
    },
    [],
  );
  const login = useCallback(
    async (input: LoginInput) => {
      if (busy.current)
        throw new ApiRequestError("A sign-in request is already in progress.");
      cancelLogin();
      const requestGeneration = generation.current;
      busy.current = true;
      try {
        clearAuthSession();
        const credentials = {
          username: input.username.trim(),
          password: input.password,
        };
        const challenge = challengeFrom(await authApi.login(credentials));
        if (requestGeneration !== generation.current)
          throw new ApiRequestError("Sign-in was cancelled. Please try again.");
        pending.current = { credentials, challenge };
        setLoginChallenge(challenge);
        onChallenge();
        return challenge;
      } finally {
        busy.current = false;
      }
    },
    [cancelLogin, onChallenge],
  );
  const resendLogin = useCallback(async () => {
    const current = pending.current;
    if (!current)
      throw new ApiRequestError(
        "Your sign-in session expired. Please sign in again.",
      );
    if (busy.current || Date.now() < current.challenge.resendAvailableAt)
      return current.challenge;
    busy.current = true;
    try {
      const challenge = challengeFrom(await authApi.login(current.credentials));
      if (pending.current !== current)
        throw new ApiRequestError(
          "Your sign-in session expired. Please sign in again.",
        );
      current.challenge = challenge;
      setLoginChallenge(challenge);
      return challenge;
    } finally {
      busy.current = false;
    }
  }, []);
  const verifyLogin = useCallback(
    async (code: string) => {
      const current = pending.current;
      if (!current)
        throw new ApiRequestError(
          "Your sign-in session expired. Please sign in again.",
        );
      if (!/^\d{6}$/.test(code))
        throw new ApiRequestError("Enter a 6-digit code.");
      if (busy.current)
        throw new ApiRequestError("Verification is already in progress.");
      busy.current = true;
      try {
        const response = await authApi.verifyLogin({
          ...current.credentials,
          code,
        });
        if (pending.current !== current)
          throw new ApiRequestError(
            "Sign-in was cancelled. Please sign in again.",
          );
        const expiration =
          typeof response.accessToken === "string"
            ? getAccessTokenExpiration(response.accessToken)
            : null;
        if (
          !expiration ||
          expiration <= Date.now() ||
          typeof response.mustChangePassword !== "boolean"
        )
          throw new ApiRequestError(
            "Unable to complete sign-in verification. Please try again.",
          );
        const profile = await authApi.getMe(response.accessToken);
        if (pending.current !== current)
          throw new ApiRequestError(
            "Sign-in was cancelled. Please sign in again.",
          );
        const user: User = {
          ...profile,
          role: normalizeUserRole(profile.role),
        };
        const mustChangePassword = Boolean(
          profile.mustChangedPassword || response.mustChangePassword,
        );
        onAuthenticated(user, response.accessToken, mustChangePassword);
        cancelLogin();
        return { user, mustChangePassword };
      } finally {
        busy.current = false;
      }
    },
    [onAuthenticated, cancelLogin],
  );
  return { loginChallenge, login, verifyLogin, resendLogin, cancelLogin };
}
