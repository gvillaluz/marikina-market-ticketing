import { Eye, EyeOff, LoaderCircle } from "lucide-react";
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
  return (
    <>
      <p id="recovery-password-description" className={styles.description}>
        Use at least 8 characters and include both letters and numbers.
      </p>
      <form className={styles.form} onSubmit={submit}>
        <label className={styles.label}>
          New password
          <span className={styles.inputWrap}>
            <input
              autoComplete="new-password"
              disabled={loading}
              className={styles.input}
              onChange={(event) => changePassword(event.target.value)}
              placeholder="Enter new password"
              type={showNewPassword ? "text" : "password"}
              value={newPassword}
              aria-invalid={Boolean(error)}
              aria-describedby={
                error ? "recovery-reset-error" : "recovery-password-description"
              }
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
        <label className={styles.label}>
          Confirm password
          <span className={styles.inputWrap}>
            <input
              autoComplete="new-password"
              disabled={loading}
              className={styles.input}
              onChange={(event) => changeConfirmation(event.target.value)}
              placeholder="Enter new password again"
              type={showConfirmPassword ? "text" : "password"}
              value={confirmPassword}
              aria-invalid={mismatch}
              aria-describedby={
                mismatch
                  ? "recovery-password-mismatch"
                  : "recovery-password-description"
              }
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
