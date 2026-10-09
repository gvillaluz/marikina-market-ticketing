import { AtSign, LockKeyhole, MessageSquare } from "lucide-react";
import type { RecoveryAccount, RecoveryChannel } from "../../recovery.types";
import RecoveryOption from "./RecoveryOption";
import RecoveryOptionsSkeleton from "./RecoveryOptionsSkeleton";
import styles from "./RecoveryOptionsPage.module.css";

interface RecoveryOptionsPageProps {
  loading: boolean;
  error: string;
  account: RecoveryAccount | null;
  onSelect: (channel: RecoveryChannel) => void;
  onBackToLogin: () => void;
  onTryAgain: () => void;
}
export default function RecoveryOptionsPage({
  loading,
  error,
  account,
  onSelect,
  onBackToLogin,
  onTryAgain,
}: RecoveryOptionsPageProps) {
  if (loading) return <RecoveryOptionsSkeleton />;
  if (error || !account)
    return (
      <div className={styles.errorState}>
        <p className={styles.error} role="alert">
          {error || "Could not find your account."}
        </p>
        <button className={styles.tryAgain} onClick={onTryAgain} type="button">
          Try another username
        </button>
      </div>
    );
  return (
    <>
      <p className={styles.description}>
        Select where you want to receive your password reset code.
      </p>
      <div className={styles.optionList}>
        <RecoveryOption
          icon={AtSign}
          title="Reset via Email"
          description={account.maskedEmail || "Your registered email address"}
          onSelect={() => onSelect("email")}
          disabled={!account.maskedEmail}
        />
        <RecoveryOption
          icon={MessageSquare}
          title="Reset via SMS number"
          description={
            account.maskedPhoneNumber || "Your registered phone number"
          }
          onSelect={() => onSelect("sms")}
          disabled={!account.maskedPhoneNumber}
        />
        <RecoveryOption
          icon={LockKeyhole}
          title="Continue with password"
          description="Sign in using your current password."
          onSelect={onBackToLogin}
        />
      </div>
    </>
  );
}
