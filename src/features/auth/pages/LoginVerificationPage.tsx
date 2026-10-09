import { ArrowLeft, LoaderCircle, ShieldCheck } from "lucide-react";
import { Navigate } from "react-router-dom";
import AuthLayout from "../components/AuthLayout";
import OtpCodeInput from "../components/OtpCodeInput";
import { useTwoFactorLogin } from "../hooks/useTwoFactorLogin";
import styles from "./LoginVerificationPage.module.css";

export default function LoginVerificationPage() {
  const model = useTwoFactorLogin();
  if (model.isAuthenticated)
    return <Navigate to={model.authenticatedPath} replace />;
  if (!model.loginChallenge)
    return (
      <Navigate
        to={model.loginPath}
        replace
        state={{ verificationExpired: true }}
      />
    );
  return (
    <AuthLayout
      subtext={model.access === "staff" ? "Admin Access" : "Vendor Access"}
      showBackHome={false}
    >
      <button
        className={styles.back}
        type="button"
        onClick={model.cancel}
        disabled={model.verifying || model.resending}
      >
        <ArrowLeft size={15} aria-hidden="true" />
        Back to sign in
      </button>
      <div className={styles.header}>
        <span className={styles.icon}>
          <ShieldCheck size={22} aria-hidden="true" />
        </span>
        <h2>SIGN-IN VERIFICATION</h2>
      </div>
      <p className={styles.description} id="login-code-description">
        Enter the 6-digit code sent to{" "}
        <strong>{model.loginChallenge.maskedEmail}</strong> to finish signing
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
          descriptionId={
            model.error ? "login-code-error" : "login-code-description"
          }
        />
        {model.expired && (
          <p className={styles.expiry} role="status">
            This code has expired. Request a new code below.
          </p>
        )}
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
              model.resendLabel
            )}
          </button>
        </div>
        {model.notice && (
          <p className={styles.notice} role="status">
            {model.notice}
          </p>
        )}
        {model.error && (
          <p className={styles.error} id="login-code-error" role="alert">
            {model.error}
          </p>
        )}
        <button
          className={styles.verify}
          type="submit"
          disabled={!model.canVerify}
        >
          {model.verifying && (
            <LoaderCircle
              className={styles.spinner}
              size={16}
              aria-hidden="true"
            />
          )}
          {model.verifying ? "Verifying…" : "Verify & sign in"}
        </button>
      </form>
    </AuthLayout>
  );
}
