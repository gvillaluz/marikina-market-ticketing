import OtpCodeInput from "../OtpCodeInput";
import { LoaderCircle } from "lucide-react";
import type { RecoveryChannel } from "@/features/auth/recovery.types";
import styles from "./VerifyCodePage.module.css";
import { useRecoveryVerification } from "../../hooks/useRecoveryVerification";
import VerifyCodeSkeleton from "./VerifyCodeSkeleton";

interface VerifyCodePageProps {
  username: string;
  channel: RecoveryChannel;
  maskedEmail: string;
  maskedPhoneNumber: string;
  onVerified: (resetToken: string) => void;
}

const VerifyCodePage = ({
  username,
  channel,
  maskedEmail,
  maskedPhoneNumber,
  onVerified,
}: VerifyCodePageProps) => {
  const {
    code,
    sending,
    resending,
    verifying,
    error,
    notice,
    sent,
    busy,
    cooldown,
    cooldownLabel,
    canResend,
    canVerify,
    setInputRef,
    changeCode: handleCodeChange,
    pasteCode,
    keyDown,
    resend: handleResend,
    verify: handleVerify,
  } = useRecoveryVerification(username, channel, onVerified);
  const contact =
    (channel === "sms" ? maskedPhoneNumber : maskedEmail) ||
    (channel === "sms"
      ? "your registered phone number"
      : "your registered email address");

  return (
    <>
      <p id="recovery-code-description" className={styles.description}>
        {sent
          ? "Enter the 6-digit code sent to"
          : sending
            ? "We’re sending a verification code to"
            : "Request a verification code for"}{" "}
        <strong>{contact}</strong>.
      </p>
      {sending ? (
        <VerifyCodeSkeleton />
      ) : (
        <form className={styles.form} onSubmit={handleVerify}>
          <OtpCodeInput
            model={{
              code,
              changeCode: handleCodeChange,
              setInputRef,
              pasteCode,
              keyDown,
            }}
            disabled={busy || !sent}
            invalid={Boolean(error)}
            descriptionId={
              error ? "recovery-code-error" : "recovery-code-description"
            }
          />
          <div className={styles.resendRow}>
            <span>Didn&apos;t receive the code?</span>
            <span className={styles.resendControls}>
              <button
                className={styles.resendButton}
                disabled={!canResend}
                onClick={handleResend}
                type="button"
              >
                {resending ? (
                  <LoaderCircle
                    className={styles.spinner}
                    size={15}
                    aria-label="Resending code"
                  />
                ) : (
                  "Resend"
                )}
              </button>
              {cooldown > 0 && (
                <span className={styles.cooldown}>{cooldownLabel}</span>
              )}
            </span>
          </div>
          {notice && (
            <p className={styles.notice} role="status">
              {notice}
            </p>
          )}
          {error && (
            <p id="recovery-code-error" className={styles.error} role="alert">
              {error}
            </p>
          )}
          <button
            className={styles.primaryButton}
            disabled={!canVerify}
            type="submit"
          >
            {verifying && (
              <LoaderCircle
                className={styles.spinner}
                size={16}
                aria-hidden="true"
              />
            )}
            {verifying ? "Verifying..." : "Verify"}
          </button>
        </form>
      )}
      {error && sending && (
        <p className={styles.error} role="alert">
          {error}
        </p>
      )}
    </>
  );
};

export default VerifyCodePage;
