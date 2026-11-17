import { Eye, EyeOff, LoaderCircle } from "lucide-react";
import CapsLockNote from "../CapsLockNote";
import PasswordRuleChecklist from "../PasswordRuleChecklist";
import { useCapsLock } from "../../hooks/useCapsLock";
import styles from "./ResetPasswordPage.module.css";
import { useRecoveryReset } from "../../hooks/useRecoveryReset";

interface ResetPasswordPageProps {
  username: string;
  resetToken: string;
  onComplete: () => void;
}

const ResetPasswordPage = ({
  username,
  resetToken,
  onComplete,
}: ResetPasswordPageProps) => {
  const {
    newPassword,
    confirmPassword,
    showNewPassword,
    showConfirmPassword,
    loading,
    error,
    mismatch,
    changePassword,
    changeConfirmation,
    togglePassword,
    toggleConfirmation,
    submit,
  } = useRecoveryReset(username, resetToken, onComplete);
  const caps = useCapsLock();
  const describedBy = (...ids: (string | false)[]) =>
    ids.filter(Boolean).join(" ") || undefined;
  return (
    <>
      <form className={styles.form} onSubmit={submit}>
        <div className={styles.field}>
          <label className={styles.label}>
            New password
            <span className={styles.inputWrap}>
              <input
                id="recovery-new-password"
                autoComplete="new-password"
                disabled={loading}
                className={styles.input}
                onChange={(event) => changePassword(event.target.value)}
                placeholder="Enter new password"
                type={showNewPassword ? "text" : "password"}
                value={newPassword}
                aria-invalid={Boolean(error)}
                aria-describedby={describedBy(
                  error ? "recovery-reset-error" : "recovery-password-rules",
                  caps.field === "recovery-new-password" &&
                    "recovery-new-password-caps",
                )}
                {...caps.bind("recovery-new-password")}
              />
              <button
                aria-label={
                  showNewPassword ? "Hide new password" : "Show new password"
                }
                className={styles.passwordToggle}
                aria-pressed={showNewPassword}
                onClick={togglePassword}
                type="button"
              >
                {showNewPassword ? <EyeOff size={16} /> : <Eye size={16} />}
              </button>
            </span>
          </label>
          {caps.field === "recovery-new-password" && (
            <CapsLockNote id="recovery-new-password-caps" />
          )}
          <PasswordRuleChecklist
            id="recovery-password-rules"
            value={newPassword}
          />
        </div>
        <div className={styles.field}>
          <label className={styles.label}>
            Confirm password
            <span className={styles.inputWrap}>
              <input
                id="recovery-confirm-password"
                autoComplete="new-password"
                disabled={loading}
                className={styles.input}
                onChange={(event) => changeConfirmation(event.target.value)}
                placeholder="Enter new password again"
                type={showConfirmPassword ? "text" : "password"}
                value={confirmPassword}
                aria-invalid={mismatch}
                aria-describedby={describedBy(
                  mismatch && "recovery-password-mismatch",
                  caps.field === "recovery-confirm-password" &&
                    "recovery-confirm-password-caps",
                )}
                {...caps.bind("recovery-confirm-password")}
              />
              <button
                aria-label={
                  showConfirmPassword
                    ? "Hide confirm password"
                    : "Show confirm password"
                }
                className={styles.passwordToggle}
                onClick={toggleConfirmation}
                aria-pressed={showConfirmPassword}
                type="button"
              >
                {showConfirmPassword ? <EyeOff size={16} /> : <Eye size={16} />}
              </button>
            </span>
            {mismatch && (
              <span
                id="recovery-password-mismatch"
                className={styles.passwordError}
              >
                Passwords do not match.
              </span>
            )}
          </label>
          {caps.field === "recovery-confirm-password" && (
            <CapsLockNote id="recovery-confirm-password-caps" />
          )}
        </div>
        {error && (
          <p id="recovery-reset-error" className={styles.error} role="alert">
            {error}
          </p>
        )}
        <button
          className={styles.primaryButton}
          disabled={loading}
          type="submit"
        >
          {loading && (
            <LoaderCircle
              className={styles.spinner}
              size={16}
              aria-hidden="true"
            />
          )}
          {loading ? "Changing password..." : "Change Password"}
        </button>
      </form>
    </>
  );
};

export default ResetPasswordPage;
