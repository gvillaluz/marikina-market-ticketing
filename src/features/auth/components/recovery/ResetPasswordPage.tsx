import { FormEvent, useState } from "react";
import { Eye, EyeOff, LoaderCircle } from "lucide-react";
import { authApi } from "@/api/endpoints/auth.api";
import styles from "./ResetPasswordPage.module.css";
import { getApiErrorMessage } from "@/utils/apiErrors";

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
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [showNewPassword, setShowNewPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setError("");
    if (newPassword.length < 8) {
      setError("Your password must be at least 8 characters long.");
      return;
    }
    if (!/[A-Za-z]/.test(newPassword) || !/\d/.test(newPassword)) {
      setError("Your password must include both letters and numbers.");
      return;
    }
    if (newPassword !== confirmPassword) {
      setError("Passwords do not match.");
      return;
    }

    setLoading(true);
    try {
      await authApi.resetPassword({ username, newPassword, resetToken });
      onComplete();
    } catch (err) {
      setError(getApiErrorMessage(err, "Could not reset your password."));
    } finally {
      setLoading(false);
    }
  };

  return (
    <>
      <p className={styles.description}>Use at least 8 characters and include both letters and numbers.</p>
      <form className={styles.form} onSubmit={handleSubmit}>
        <label className={styles.label}>
          New password
          <span className={styles.inputWrap}>
            <input
              autoComplete="new-password"
              className={styles.input}
              onChange={(event) => setNewPassword(event.target.value)}
              placeholder="Enter new password"
              type={showNewPassword ? "text" : "password"}
              value={newPassword}
            />
            <button
              aria-label={showNewPassword ? "Hide new password" : "Show new password"}
              className={styles.passwordToggle}
              onClick={() => setShowNewPassword(!showNewPassword)}
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
              className={styles.input}
              onChange={(event) => setConfirmPassword(event.target.value)}
              placeholder="Enter new password again"
              type={showConfirmPassword ? "text" : "password"}
              value={confirmPassword}
            />
            <button
              aria-label={showConfirmPassword ? "Hide confirm password" : "Show confirm password"}
              className={styles.passwordToggle}
              onClick={() => setShowConfirmPassword(!showConfirmPassword)}
              type="button"
            >
              {showConfirmPassword ? <EyeOff size={16} /> : <Eye size={16} />}
            </button>
          </span>
          {confirmPassword && newPassword !== confirmPassword && (
            <span className={styles.passwordError}>Passwords do not match.</span>
          )}
        </label>
        {error && <p className={styles.error} role="alert">{error}</p>}
        <button className={styles.primaryButton} disabled={loading} type="submit">
          {loading && <LoaderCircle className={styles.spinner} size={16} />}
          {loading ? "Changing password..." : "Change Password"}
        </button>
      </form>
    </>
  );
};

export default ResetPasswordPage;
