import AuthSubmitButton from "../AuthSubmitButton";
import OtpCodeInput from "../OtpCodeInput";
import ResendRing from "../ResendRing";
import RevealMessage from "../RevealMessage";
import { LoaderCircle } from "lucide-react";
import type { RecoveryChannel } from "@/features/auth/recovery.types";
import styles from "./VerifyCodePage.module.css";
import { useRecoveryVerification } from "../../hooks/useRecoveryVerification";
import VerifyCodeSkeleton from "./VerifyCodeSkeleton";

interface VerifyCodePageProps {
  username: string;
  channel: RecoveryChannel;
  maskedEmail: string;
  onVerified: (resetToken: string) => void;
}

const VerifyCodePage = ({
  username,
  channel,
  maskedEmail,
  onVerified,
}: VerifyCodePageProps) => {
  const {
    code,
    sending,
    resending,
    verifying,
    succeeded,
    error,
    notice,
    sent,
    busy,
    cooldown,
    cooldownLabel,
    resendProgress,
    canResend,
    canVerify,
    setInputRef,
    changeCode: handleCodeChange,
    pasteCode,
    keyDown,
    resend: handleResend,
    verify: handleVerify,
  } = useRecoveryVerification(username, channel, onVerified);
  const contact = maskedEmail || "your registered email address";

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
            success={succeeded}
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
                <span className={styles.cooldown}>
                  <ResendRing progress={resendProgress} />
                  {cooldownLabel}
                </span>
              )}
            </span>
          </div>
          <RevealMessage
            message={notice}
            className={styles.notice}
            role="status"
          />
          <RevealMessage
            message={error}
            id="recovery-code-error"
            className={styles.error}
            role="alert"
          />
          <AuthSubmitButton
            label="Verify"
            busyLabel="Verifying..."
            busy={verifying}
            done={succeeded}
            disabled={!canVerify}
            className={styles.primaryButton}
          />
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
