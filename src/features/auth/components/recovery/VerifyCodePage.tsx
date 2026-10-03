import { FormEvent, useEffect, useRef, useState } from "react";
import { LoaderCircle } from "lucide-react";
import { authApi } from "@/api/endpoints/auth.api";
import type { RecoveryChannel } from "@/features/auth/recovery.types";
import styles from "./VerifyCodePage.module.css";
import { getApiErrorMessage } from "@/utils/apiErrors";

interface VerifyCodePageProps {
  username: string;
  channel: RecoveryChannel;
  maskedEmail: string;
  maskedPhoneNumber: string;
  onVerified: (resetToken: string) => void;
}

const CODE_LENGTH = 6;

const VerifyCodePage = ({
  username,
  channel,
  maskedEmail,
  maskedPhoneNumber,
  onVerified,
}: VerifyCodePageProps) => {
  const [code, setCode] = useState<string[]>(Array(CODE_LENGTH).fill(""));
  const [cooldown, setCooldown] = useState(0);
  const [sending, setSending] = useState(true);
  const [resending, setResending] = useState(false);
  const [verifying, setVerifying] = useState(false);
  const [error, setError] = useState("");
  const refs = useRef<Array<HTMLInputElement | null>>([]);
  const contact = channel === "sms" ? maskedPhoneNumber : maskedEmail;

  const sendCode = async () => {
    const response = await authApi.sendCode(username, channel);
    setCooldown(response.resendCooldownSeconds);
  };

  useEffect(() => {
    let cancelled = false;
    setSending(true);
    setError("");
    authApi.sendCode(username, channel)
      .then((response) => {
        if (!cancelled) setCooldown(response.resendCooldownSeconds);
      })
      .catch((err: unknown) => {
        if (!cancelled) {
          setError(getApiErrorMessage(err, "Could not send the verification code."));
        }
      })
      .finally(() => {
        if (!cancelled) setSending(false);
      });
    return () => {
      cancelled = true;
    };
  }, [username, channel]);

  useEffect(() => {
    if (cooldown <= 0) return;
    const timer = window.setInterval(() => {
      setCooldown((remaining) => Math.max(0, remaining - 1));
    }, 1000);
    return () => window.clearInterval(timer);
  }, [cooldown > 0]);

  const handleResend = async () => {
    if (cooldown > 0 || resending || sending) return;
    setError("");
    setCooldown(0);
    setResending(true);
    try {
      await sendCode();
      setCode(Array(CODE_LENGTH).fill(""));
      refs.current[0]?.focus();
    } catch (err) {
      setError(getApiErrorMessage(err, "Could not resend the verification code."));
    } finally {
      setResending(false);
    }
  };

  const handleCodeChange = (index: number, value: string) => {
    const digits = value.replace(/\D/g, "").slice(0, CODE_LENGTH - index);
    const nextCode = [...code];
    if (!digits) {
      nextCode[index] = "";
      setCode(nextCode);
      return;
    }
    digits.split("").forEach((digit, offset) => {
      nextCode[index + offset] = digit;
    });
    setCode(nextCode);
    refs.current[Math.min(index + digits.length, CODE_LENGTH - 1)]?.focus();
  };

  const handleVerify = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setError("");
    if (code.join("").length !== CODE_LENGTH) {
      setError("Enter the 6-digit verification code.");
      return;
    }

    setVerifying(true);
    try {
      const result = await authApi.verifyCode(username, code.join(""));
      if (!result.success || !result.resetToken) {
        setError(result.message || "The verification code is invalid.");
        return;
      }
      onVerified(result.resetToken);
    } catch (err) {
      setError(getApiErrorMessage(err, "Could not verify the code."));
    } finally {
      setVerifying(false);
    }
  };

  return (
    <>
      <p className={styles.description}>
        We&apos;ve sent a 6-digit verification code to {contact}.
      </p>
      {sending ? (
        <div className={styles.sendingMessage} role="status">
          <LoaderCircle className={styles.spinner} size={18} />
          Sending verification code...
        </div>
      ) : (
        <form className={styles.form} onSubmit={handleVerify}>
          <div className={styles.codeInputs}>
            {code.map((digit, index) => (
              <input
                key={index}
                ref={(element) => { refs.current[index] = element; }}
                aria-label={`Verification digit ${index + 1}`}
                autoComplete={index === 0 ? "one-time-code" : "off"}
                className={styles.codeInput}
                inputMode="numeric"
                maxLength={CODE_LENGTH}
                onChange={(event) => handleCodeChange(index, event.target.value)}
                onKeyDown={(event) => {
                  if (event.key === "Backspace" && !code[index] && index > 0) {
                    refs.current[index - 1]?.focus();
                  }
                }}
                value={digit}
              />
            ))}
          </div>
          <div className={styles.resendRow}>
            <span>Didn&apos;t receive the code?</span>
            <span className={styles.resendControls}>
              <button
                className={styles.resendButton}
                disabled={cooldown > 0 || resending}
                onClick={handleResend}
                type="button"
              >
                {resending ? <LoaderCircle className={styles.spinner} size={15} aria-label="Resending code" /> : "Resend"}
              </button>
              {cooldown > 0 && (
                <span className={styles.cooldown}>
                  {`${String(Math.floor(cooldown / 60)).padStart(2, "0")}:${String(cooldown % 60).padStart(2, "0")}`}
                </span>
              )}
            </span>
          </div>
          {error && <p className={styles.error} role="alert">{error}</p>}
          <button className={styles.primaryButton} disabled={verifying} type="submit">
            {verifying && <LoaderCircle className={styles.spinner} size={16} />}
            {verifying ? "Verifying..." : "Verify"}
          </button>
        </form>
      )}
      {error && sending && <p className={styles.error} role="alert">{error}</p>}
    </>
  );
};

export default VerifyCodePage;
