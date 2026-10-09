import {
  useEffect,
  useRef,
  useState,
  type ClipboardEvent,
  type FormEvent,
  type KeyboardEvent,
} from "react";
import { authApi, type SendCodeResponse } from "@/api/endpoints/auth.api";
import { getApiErrorMessage } from "@/utils/apiErrors";
import type { RecoveryChannel } from "../recovery.types";

const CODE_LENGTH = 6;
function cooldownSeconds(value: number) {
  return Number.isSafeInteger(value) && value >= 0 ? Math.min(value, 86400) : 0;
}

export function useRecoveryVerification(
  username: string,
  channel: RecoveryChannel,
  onVerified: (resetToken: string) => void,
) {
  const [code, setCode] = useState<string[]>(Array(CODE_LENGTH).fill(""));
  const [cooldown, setCooldown] = useState(0);
  const [sending, setSending] = useState(true);
  const [resending, setResending] = useState(false);
  const [verifying, setVerifying] = useState(false);
  const [sent, setSent] = useState(false);
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");
  const refs = useRef<Array<HTMLInputElement | null>>([]);
  const initialRequest = useRef<{
    key: string;
    promise: Promise<SendCodeResponse>;
  } | null>(null);
  const busy = useRef(false);
  const mounted = useRef(false);
  useEffect(() => {
    mounted.current = true;
    return () => {
      mounted.current = false;
    };
  }, []);
  useEffect(() => {
    let cancelled = false;
    const key = `${username}:${channel}`;
    if (initialRequest.current?.key !== key)
      initialRequest.current = {
        key,
        promise: authApi.sendCode(username, channel),
      };
    initialRequest.current.promise
      .then((response) => {
        if (cancelled) return;
        setCooldown(cooldownSeconds(response.resendCooldownSeconds));
        setSent(true);
      })
      .catch((failure: unknown) => {
        if (!cancelled)
          setError(
            getApiErrorMessage(
              failure,
              "Could not send the verification code. Please try again.",
            ),
          );
      })
      .finally(() => {
        if (!cancelled) setSending(false);
      });
    return () => {
      cancelled = true;
    };
  }, [username, channel]);
  const hasCooldown = cooldown > 0;
  useEffect(() => {
    if (!hasCooldown) return;
    const timer = window.setInterval(
      () => setCooldown((value) => Math.max(0, value - 1)),
      1000,
    );
    return () => window.clearInterval(timer);
  }, [hasCooldown]);
  useEffect(() => {
    if (!sending && !resending && sent) refs.current[0]?.focus();
  }, [sending, resending, sent]);
  function changeCode(index: number, value: string) {
    if (busy.current || sending) return;
    const digits = value.replace(/\D/g, "").slice(0, CODE_LENGTH - index);
    setCode((previous) => {
      const next = [...previous];
      if (!digits) next[index] = "";
      else
        digits.split("").forEach((digit, offset) => {
          next[index + offset] = digit;
        });
      return next;
    });
    setError("");
    setNotice("");
    if (digits)
      refs.current[Math.min(index + digits.length, CODE_LENGTH - 1)]?.focus();
  }
  return {
    code,
    cooldown,
    sending,
    resending,
    verifying,
    error,
    notice,
    sent,
    busy: sending || resending || verifying,
    cooldownLabel: `${String(Math.floor(cooldown / 60)).padStart(2, "0")}:${String(cooldown % 60).padStart(2, "0")}`,
    canResend: !hasCooldown && !sending && !resending && !verifying,
    canVerify: sent && !sending && !resending && !verifying,
    setInputRef(index: number, element: HTMLInputElement | null) {
      refs.current[index] = element;
    },
    changeCode,
    pasteCode(index: number, event: ClipboardEvent<HTMLInputElement>) {
      event.preventDefault();
      changeCode(index, event.clipboardData.getData("text"));
    },
    keyDown(index: number, event: KeyboardEvent<HTMLInputElement>) {
      if (event.key === "ArrowLeft" && index > 0) {
        event.preventDefault();
        refs.current[index - 1]?.focus();
      }
      if (event.key === "ArrowRight" && index < CODE_LENGTH - 1) {
        event.preventDefault();
        refs.current[index + 1]?.focus();
      }
      if (event.key === "Backspace" && !code[index] && index > 0) {
        event.preventDefault();
        refs.current[index - 1]?.focus();
      }
    },
    async resend() {
      if (busy.current || hasCooldown || sending) return;
      busy.current = true;
      setResending(true);
      setError("");
      setNotice("");
      try {
        const response = await authApi.sendCode(username, channel);
        if (!mounted.current) return;
        setCooldown(cooldownSeconds(response.resendCooldownSeconds));
        setSent(true);
        setCode(Array(CODE_LENGTH).fill(""));
        setNotice("A new code has been sent.");
        refs.current[0]?.focus();
      } catch (failure) {
        if (mounted.current)
          setError(
            getApiErrorMessage(
              failure,
              "Could not resend the verification code. Please try again.",
            ),
          );
      } finally {
        busy.current = false;
        if (mounted.current) setResending(false);
      }
    },
    async verify(event: FormEvent<HTMLFormElement>) {
      event.preventDefault();
      if (busy.current || sending || !sent) return;
      setError("");
      setNotice("");
      if (!/^\d{6}$/.test(code.join(""))) {
        setError("Enter the 6-digit verification code.");
        refs.current[code.findIndex((digit) => !digit)]?.focus();
        return;
      }
      busy.current = true;
      setVerifying(true);
      try {
        const result = await authApi.verifyCode(username, code.join(""));
        if (!mounted.current) return;
        if (
          !result.success ||
          typeof result.resetToken !== "string" ||
          !result.resetToken.trim()
        ) {
          setError(result.message || "The verification code is invalid.");
          return;
        }
        onVerified(result.resetToken);
      } catch (failure) {
        if (mounted.current)
          setError(
            getApiErrorMessage(
              failure,
              "Could not verify the code. Please try again.",
            ),
          );
      } finally {
        busy.current = false;
        if (mounted.current) setVerifying(false);
      }
    },
  };
}
