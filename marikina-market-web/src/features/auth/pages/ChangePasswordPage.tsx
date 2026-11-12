import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Lock, KeyRound, ShieldCheck, ArrowLeft } from "lucide-react";
import { useAuth } from "@/context/AuthContext";
import { authApi } from "@/api/endpoints/auth.api";
import { useToast } from "@/components/ui/Toast/useToast";
import { PASSWORD_RULE_HINT, validatePasswordForm } from "@/features/profile";
import styles from "./ChangePasswordPage.module.css";
import { getApiErrorMessage } from "@/utils/apiErrors";

export default function ChangePasswordPage() {
  const [currentPassword, setCurrentPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const { logout } = useAuth();
  const { showToast } = useToast();
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setError(null);
    const [firstError] = Object.values(
      validatePasswordForm({
        currentPassword,
        newPassword,
        confirmNewPassword: confirmPassword,
      }),
    );
    if (firstError) return setError(firstError);
    setLoading(true);
    try {
      await authApi.mandatoryChangePassword({
        currentPassword,
        newPassword,
        confirmNewPassword: confirmPassword,
      });
      showToast({
        title: "Password changed",
        description: "Please sign in again with your new password.",
        variant: "success",
      });
      logout();
    } catch (err: unknown) {
      setError(
        getApiErrorMessage(err, "Failed to change password. Please try again."),
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className={`route-motion ${styles.page}`}>
      <button
        type="button"
        onClick={() => navigate(-1)}
        className={styles.backButton}
      >
        <ArrowLeft size={16} />
        Back Home
      </button>
      <div className={styles.card}>
        <div className={styles.brandPanel}>
          <div className={styles.seal}>
            <div className={styles.sealMark}>SEAL</div>
          </div>
          <h2 className={styles.brandTitle}>
            Marikina Public Market
            <br />
            Inspection System
          </h2>
          <p className={styles.brandSubtitle}>Admin Access</p>
        </div>
        <div className={styles.formPanel}>
          <h1 className={styles.heading}>CHANGE PASSWORD</h1>
          <form onSubmit={handleSubmit} className={styles.form} noValidate>
            <div>
              <label className={styles.label}>Current Password</label>
              <div className={styles.inputWrapper}>
                <Lock className={styles.inputIcon} size={16} />
                <input
                  type="password"
                  value={currentPassword}
                  onChange={(e) => setCurrentPassword(e.target.value)}
                  placeholder="Enter current password"
                  className={styles.input}
                />
              </div>
            </div>
            <div>
              <label className={styles.label}>New Password</label>
              <div className={styles.inputWrapper}>
                <KeyRound className={styles.inputIcon} size={16} />
                <input
                  type="password"
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                  placeholder="Enter new password"
                  className={styles.input}
                />
              </div>
              <p className={styles.hint}>{PASSWORD_RULE_HINT}</p>
            </div>
            <div>
              <label className={styles.label}>Confirm New Password</label>
              <div className={styles.inputWrapper}>
                <ShieldCheck className={styles.inputIcon} size={16} />
                <input
                  type="password"
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  placeholder="Re-enter new password"
                  className={styles.input}
                />
              </div>
            </div>
            {error && <p className={styles.error}>{error}</p>}
            <button type="submit" disabled={loading} className={styles.submit}>
              {loading ? "SAVING..." : "SAVE PASSWORD"}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}
