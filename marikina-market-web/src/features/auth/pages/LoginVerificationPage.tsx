import { ArrowLeft, LoaderCircle } from "lucide-react";
import { Navigate } from "react-router-dom";
import { ROUTES } from "@/routes/routePaths";
import AuthLayout from "../components/AuthLayout";
import AuthSubmitButton from "../components/AuthSubmitButton";
import OtpCodeInput from "../components/OtpCodeInput";
import RevealMessage from "../components/RevealMessage";
import ResendRing from "../components/ResendRing";
import { useTwoFactorLogin } from "../hooks/useTwoFactorLogin";
import styles from "./LoginVerificationPage.module.css";

export default function LoginVerificationPage() {
  const model = useTwoFactorLogin();
  // While the success tick shows, the challenge is already cleared; stay put.
  if (!model.verifying) {
    if (model.isAuthenticated)
      return <Navigate to={model.authenticatedPath} replace />;
    if (!model.loginChallenge)
      return (
        <Navigate
          to={ROUTES.adminLogin}
          replace
          state={{ verificationExpired: true }}
        />
      );
  }
  return (
    <AuthLayout>
      <button
        className={styles.back}
        type="button"
        onClick={model.cancel}
        disabled={model.verifying || model.resending}
      >
        <ArrowLeft size={15} aria-hidden="true" />
        Back to log in
      </button>
      <h2 className={styles.heading}>Sign-in verification</h2>
      <p className={styles.description} id="login-code-description">
        Enter the 6-digit code sent to{" "}
        <strong>{model.maskedEmail}</strong> to finish logging
        in.
      </p>
      <form
        className={styles.form}
        onSubmit={model.verify}
        aria-busy={model.verifying || model.resending}
      >
        <OtpCodeInput
          model={model.otp}
          disabled={!model.canVerify}
          invalid={Boolean(model.error)}
          success={model.succeeded}
          descriptionId={
            model.error ? "login-code-error" : "login-code-description"
          }
        />
        <RevealMessage
          message={
            model.expired
              ? "This code has expired. Request a new code below."
              : ""
          }
          className={styles.expiry}
          role="status"
        />
        <div className={styles.resendRow}>
          <span>Didn’t receive the email?</span>
          <button
            type="button"
            className={styles.resend}
            disabled={!model.canResend}
            onClick={model.resend}
          >
            {model.resending ? (
              <>
                <LoaderCircle
                  className={styles.spinner}
                  size={15}
                  aria-hidden="true"
                />
                Sending…
              </>
            ) : (
              <>
                {model.cooldownSeconds > 0 && (
                  <ResendRing progress={model.resendProgress} />
                )}
                {model.resendLabel}
              </>
            )}
          </button>
        </div>
        <RevealMessage
          message={model.notice}
          className={styles.notice}
          role="status"
        />
        <RevealMessage
          message={model.error}
          id="login-code-error"
          className={styles.error}
          role="alert"
        />
        <AuthSubmitButton
          label="Verify and log in"
          busyLabel="Verifying…"
          busy={model.verifying}
          done={model.succeeded}
          disabled={!model.canVerify}
          className={styles.verify}
        />
      </form>
    </AuthLayout>
  );
}
