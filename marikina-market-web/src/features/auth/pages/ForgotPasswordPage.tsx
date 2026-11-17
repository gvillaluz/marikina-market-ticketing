import { ArrowLeft } from "lucide-react";
import { Link, Navigate } from "react-router-dom";
import AuthLayout from "@/features/auth/components/AuthLayout";
import AccountLookupPage from "@/features/auth/components/recovery/AccountLookupPage";
import RecoveryOptionsPage from "@/features/auth/components/recovery/RecoveryOptionsPage";
import VerifyCodePage from "@/features/auth/components/recovery/VerifyCodePage";
import ResetPasswordPage from "@/features/auth/components/recovery/ResetPasswordPage";
import styles from "./ForgotPasswordPage.module.css";
import { usePasswordRecovery } from "../hooks/usePasswordRecovery";

const ForgotPasswordPage = () => {
  const {
    flow,
    basePath,
    loginPath,
    step,
    stepKey,
    accountLookup,
    lookupError,
    lookupLoading,
    invalidFlow,
    title,
    headingRef,
    findAccount,
    selectChannel,
    tryAgain,
    backToLogin,
    verified,
    complete,
  } = usePasswordRecovery();
  if (invalidFlow) {
    return (
      <Navigate
        to={`${basePath}/find-account`}
        replace
        state={{ error: "Your recovery session expired. Please start again." }}
      />
    );
  }

  return (
    <AuthLayout>
      <div className={styles.recovery}>
        <Link to={loginPath} className={styles.backLink}>
          <ArrowLeft size={15} aria-hidden="true" />
          Back to log in
        </Link>
        <div key={stepKey} className={styles.stepView}>
          <h2 ref={headingRef} tabIndex={-1} className={styles.heading}>
            {title}
          </h2>
          {step === "find-account" && (
            <AccountLookupPage
              initialUsername={flow.username ?? ""}
              initialError={flow.error ?? ""}
              onContinue={findAccount}
            />
          )}
          {step === "options" && (
            <RecoveryOptionsPage
              loading={lookupLoading}
              error={lookupError}
              account={accountLookup}
              onSelect={selectChannel}
              onBackToLogin={backToLogin}
              onTryAgain={tryAgain}
            />
          )}
          {step === "verify" && flow.channel && (
            <VerifyCodePage
              username={flow.username ?? ""}
              channel={flow.channel}
              maskedEmail={flow.maskedEmail ?? ""}
              onVerified={verified}
            />
          )}
          {step === "reset" && flow.resetToken && (
            <ResetPasswordPage
              username={flow.username ?? ""}
              resetToken={flow.resetToken}
              onComplete={complete}
            />
          )}
        </div>
      </div>
    </AuthLayout>
  );
};

export default ForgotPasswordPage;
