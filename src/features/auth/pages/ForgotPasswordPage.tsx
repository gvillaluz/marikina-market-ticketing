import { useEffect, useRef, useState } from "react";
import { ArrowLeft } from "lucide-react";
import { Link, Navigate, useLocation, useNavigate, useParams } from "react-router-dom";
import { authApi } from "@/api/endpoints/auth.api";
import citySeal from "@/assets/icons/Marikina_City_Seal.svg (1).webp";
import { ROUTES } from "@/routes/routePaths";
import AccountLookupPage from "@/features/auth/components/recovery/AccountLookupPage";
import RecoveryOptionsPage from "@/features/auth/components/recovery/RecoveryOptionsPage";
import VerifyCodePage from "@/features/auth/components/recovery/VerifyCodePage";
import ResetPasswordPage from "@/features/auth/components/recovery/ResetPasswordPage";
import type { RecoveryChannel, RecoveryState } from "@/features/auth/recovery.types";
import styles from "./ForgotPasswordPage.module.css";
import { getApiErrorMessage } from "@/utils/apiErrors";

type RecoveryRole = "Admin" | "Vendor";
type RecoveryStep = "find-account" | "options" | "verify" | "reset";

const ForgotPasswordPage = () => {
  const { step: routeStep } = useParams<{ step?: string }>();
  const location = useLocation();
  const navigate = useNavigate();
  const flow = (location.state as RecoveryState | null) ?? {};
  const role: RecoveryRole = location.pathname.startsWith("/admin/") ? "Admin" : "Vendor";
  const basePath = ROUTES.forgotPassword(role);
  const loginPath = role === "Admin" ? ROUTES.adminLogin : ROUTES.login;
  const step: RecoveryStep = ["find-account", "options", "verify", "reset"].includes(routeStep ?? "")
    ? (routeStep as RecoveryStep)
    : "find-account";

  const [lookupLoading, setLookupLoading] = useState(false);
  const [accountLookup, setAccountLookup] = useState<{
    maskedEmail: string;
    maskedPhoneNumber: string;
  } | null>(null);
  const [lookupError, setLookupError] = useState("");
  const lookupRequest = useRef("");

  useEffect(() => {
    if (step !== "options") {
      lookupRequest.current = "";
      return;
    }

    if (!flow.username?.trim()) return;
    const username = flow.username.trim();
    if (lookupRequest.current === username) return;
    lookupRequest.current = username;

    let cancelled = false;
    setLookupLoading(true);
    setLookupError("");
    setAccountLookup(null);
    authApi.findAccount(username).then((account) => {
      if (cancelled) return;
      if (!account.found) {
        setLookupError("We could not find an account with that username.");
        return;
      }
      setAccountLookup({
        maskedEmail: account.maskedEmail,
        maskedPhoneNumber: account.maskedPhoneNumber,
      });
    }).catch((err: unknown) => {
      if (!cancelled) {
        setLookupError(getApiErrorMessage(err, "Could not find your account."));
      }
    }).finally(() => {
      if (!cancelled) setLookupLoading(false);
    });

    return () => {
      cancelled = true;
      if (lookupRequest.current === username) lookupRequest.current = "";
    };
  }, [flow.username, step]);

  const goTo = (nextStep: RecoveryStep, state: RecoveryState) => {
    navigate(`${basePath}/${nextStep}`, { state });
  };

  const invalidFlow =
    (step === "options" && !flow.username) ||
    (step === "verify" && (!flow.username || !flow.channel)) ||
    (step === "reset" && (!flow.username || !flow.resetToken));

  if (invalidFlow) {
    return (
      <Navigate
        to={`${basePath}/find-account`}
        replace
        state={{ error: "Your recovery session expired. Please start again." }}
      />
    );
  }

  const title = {
    "find-account": "FIND YOUR ACCOUNT",
    options: "FORGOT PASSWORD",
    verify: flow.channel === "sms" ? "CHECK YOUR SMS" : "CHECK YOUR EMAIL",
    reset: "CREATE NEW PASSWORD",
  }[step];

  return (
    <main key={step} className={`route-motion ${styles.page}`}>
      <div className={styles.cardContainer}>
        <section className={styles.card}>
          <aside className={styles.brandPanel}>
            <img className={styles.seal} src={citySeal} alt="Marikina City seal" />
            <h1 className={styles.brandTitle}>Marikina Public Market Inspection System</h1>
            <p className={styles.brandSubtitle}>{role} Access</p>
          </aside>
          <div className={styles.content}>
            <Link to={loginPath} className={styles.backLink}>
              <ArrowLeft size={15} />
              Back to Login
            </Link>
            <h2 className={styles.heading}>{title}</h2>

            {step === "find-account" && (
              <AccountLookupPage
                initialUsername={flow.username ?? ""}
                initialError={flow.error ?? ""}
                onContinue={(username) => goTo("options", { username })}
              />
            )}
            {step === "options" && (
              <RecoveryOptionsPage
                loading={lookupLoading}
                error={lookupError}
                account={accountLookup}
                onSelect={(channel: RecoveryChannel) =>
                  goTo("verify", { username: flow.username, ...accountLookup, channel })
                }
                onBackToLogin={() => navigate(loginPath, { replace: true })}
                onTryAgain={() => goTo("find-account", { username: flow.username })}
              />
            )}
            {step === "verify" && flow.channel && (
              <VerifyCodePage
                username={flow.username ?? ""}
                channel={flow.channel}
                maskedEmail={flow.maskedEmail ?? ""}
                maskedPhoneNumber={flow.maskedPhoneNumber ?? ""}
                onVerified={(resetToken) => goTo("reset", { username: flow.username, resetToken })}
              />
            )}
            {step === "reset" && flow.resetToken && (
              <ResetPasswordPage
                username={flow.username ?? ""}
                resetToken={flow.resetToken}
                onComplete={() => navigate(loginPath, { replace: true, state: { passwordReset: true } })}
              />
            )}
          </div>
        </section>
      </div>
    </main>
  );
};

export default ForgotPasswordPage;
