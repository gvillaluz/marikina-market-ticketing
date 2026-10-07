import { AtSign, LoaderCircle, LockKeyhole, MessageSquare } from "lucide-react";
import type { RecoveryAccount, RecoveryChannel } from "@/features/auth/recovery.types";
import styles from "./RecoveryOptionsPage.module.css";

interface RecoveryOptionsPageProps {
  loading: boolean;
  error: string;
  account: RecoveryAccount | null;
  onSelect: (channel: RecoveryChannel) => void;
  onBackToLogin: () => void;
  onTryAgain: () => void;
}

const RecoveryOptionsPage = ({
  loading,
  error,
  account,
  onSelect,
  onBackToLogin,
  onTryAgain,
}: RecoveryOptionsPageProps) => {
  if (loading) {
    return (
      <div className={styles.loading} role="status">
        <LoaderCircle className={styles.spinner} size={22} />
        Finding your account...
      </div>
    );
  }

  if (error || !account) {
    return (
      <div className={styles.errorState}>
        <p className={styles.error} role="alert">{error || "Could not find your account."}</p>
        <button className={styles.tryAgain} onClick={onTryAgain} type="button">
          Try another username
        </button>
      </div>
    );
  }

  return (
    <>
      <p className={styles.description}>Please select an option to receive the password reset code.</p>
      <div className={styles.optionList}>
        <button className={styles.option} onClick={() => onSelect("email")} type="button">
          <AtSign className={styles.optionIcon} size={18} />
          <span>
            <span className={styles.optionTitle}>Reset via Email</span>
            <span className={styles.optionDescription}>To reset your password, a code will be sent to your email.</span>
          </span>
        </button>
        <button className={styles.option} onClick={() => onSelect("sms")} type="button">
          <MessageSquare className={styles.optionIcon} size={18} />
          <span>
            <span className={styles.optionTitle}>Reset via SMS number</span>
            <span className={styles.optionDescription}>To reset your password, a code will be sent to your SMS number.</span>
          </span>
        </button>
        <button className={styles.option} onClick={onBackToLogin} type="button">
          <LockKeyhole className={styles.optionIcon} size={18} />
          <span>
            <span className={styles.optionTitle}>Continue with password</span>
            <span className={styles.optionDescription}>Use your currently stored password.</span>
          </span>
        </button>
      </div>
    </>
  );
};

export default RecoveryOptionsPage;
