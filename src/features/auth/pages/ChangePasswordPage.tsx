import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Lock, KeyRound, ShieldCheck, ArrowLeft } from 'lucide-react';
import { useAuth } from '@/context/AuthContext';
import { authApi } from '@/api/endpoints/auth.api';
import { ROUTES } from '@/routes/routePaths';
import styles from './ChangePasswordPage.module.css';

export default function ChangePasswordPage() {
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const { clearMustChangePassword } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setError(null);
    if (!currentPassword) return setError('Enter your current password.');
    if (newPassword.length < 6) return setError('New password must be at least 6 characters.');
    if (!/\d/.test(newPassword)) return setError('New password must contain at least one number.');
    if (newPassword !== confirmPassword) return setError('Passwords do not match.');
    setLoading(true);
    try {
      await authApi.mandatoryChangePassword({
        current_password: currentPassword,
        new_password: newPassword,
        confirm_new_password: confirmPassword,
      });
      clearMustChangePassword();
      navigate(ROUTES.dashboard, { replace: true });
    } catch (err: any) {
      setError(err?.response?.data?.message ?? 'Failed to change password. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className={`route-motion ${styles.page}`}>
      <button type="button" onClick={() => navigate(-1)} className={styles.backButton}>
        <ArrowLeft size={16} />
        Back Home
      </button>
      <div className={styles.card}>
        <div className={styles.brandPanel}>
          <div className={styles.seal}>
            <div className={styles.sealMark}>SEAL</div>
          </div>
          <h2 className={styles.brandTitle}>Marikina Public Market<br />Inspection System</h2>
          <p className={styles.brandSubtitle}>Admin Access</p>
        </div>
        <div className={styles.formPanel}>
          <h1 className={styles.heading}>CHANGE PASSWORD</h1>
          <form onSubmit={handleSubmit} className={styles.form} noValidate>
            <div>
              <label className={styles.label}>Current Password</label>
              <div className={styles.inputWrapper}>
                <Lock className={styles.inputIcon} size={16} />
                <input type="password" value={currentPassword} onChange={(e) => setCurrentPassword(e.target.value)} placeholder="Enter current password" className={styles.input} />
              </div>
            </div>
            <div>
              <label className={styles.label}>New Password</label>
              <div className={styles.inputWrapper}>
                <KeyRound className={styles.inputIcon} size={16} />
                <input type="password" value={newPassword} onChange={(e) => setNewPassword(e.target.value)} placeholder="Enter new password" className={styles.input} />
              </div>
              <p className={styles.hint}>Min. 6 characters, at least 1 number.</p>
            </div>
            <div>
              <label className={styles.label}>Confirm New Password</label>
              <div className={styles.inputWrapper}>
                <ShieldCheck className={styles.inputIcon} size={16} />
                <input type="password" value={confirmPassword} onChange={(e) => setConfirmPassword(e.target.value)} placeholder="Re-enter new password" className={styles.input} />
              </div>
            </div>
            {error && <p className={styles.error}>{error}</p>}
            <button type="submit" disabled={loading} className={styles.submit}>
              {loading ? 'SAVING...' : 'SAVE PASSWORD'}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}
