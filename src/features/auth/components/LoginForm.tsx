import { FormEvent, FC, useState } from "react";
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { ROUTES } from '@/routes/routePaths';
import { resolveLoginIdentifier } from '@/features/auth/auth.utils';
import type { LoginFormValues } from '@/features/auth/hooks/useLogin';
import styles from './LoginForm.module.css';

interface LoginFormProps {
  showRegisterLink?: boolean;
  role?: 'Admin' | 'Enforcer' | 'Vendor';
  submit: (values: LoginFormValues) => Promise<void>;
  loading: boolean;
  error: string | null;
}

type FieldErrors = {
  username?: string;
  password?: string;
};

const LoginForm: FC<LoginFormProps> = ({
  showRegisterLink = true,
  role,
  submit,
  loading,
  error,
}) => {
  const navigate = useNavigate();
  const location = useLocation();
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [fieldErrors, setFieldErrors] = useState<FieldErrors>({});
  const passwordReset = (
    location.state as { passwordReset?: boolean } | null
  )?.passwordReset;

  const handleForgotPassword = () => {
    const nextStep = username.trim() ? "options" : "find-account";
    const recoveryRole = role === "Admin" ? "Admin" : "Vendor";
    navigate(`${ROUTES.forgotPassword(recoveryRole)}/${nextStep}`, {
      state: { username: username.trim() },
    });
  };

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const errors: FieldErrors = {};
    const isAdminLogin = role === "Admin";

    if (!username.trim()) {
      errors.username = "Enter your username.";
    } else if (!isAdminLogin && !resolveLoginIdentifier(username)) {
      errors.username = "Enter your username or email.";
    }

    if (!password.trim()) {
      errors.password = "Enter your password.";
    } else if (!isAdminLogin && password.length < 6) {
      errors.password = "Password must be at least 6 characters.";
    }

    setFieldErrors(errors);
    if (Object.keys(errors).length > 0) return;

    await submit({ username, password });
  };

  return (
    <div className={styles.formWrapper}>
      <h2 className={styles.heading}>LOGIN</h2>

      {passwordReset && (
        <div className={`${styles.message} ${styles.successMessage}`} role="status">
          Your password has been changed. Please log in with your new password.
        </div>
      )}

      {error && (
        <div className={`${styles.message} ${styles.errorMessage}`}>
          {error}
        </div>
      )}

      <form className={styles.form} onSubmit={handleSubmit}>
        <div className={styles.field}>
          <label className={styles.label}>Username</label>
          <div className={styles.inputWrapper}>
            <span className={styles.icon} aria-hidden>
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
                <circle cx="12" cy="7" r="4" />
              </svg>
            </span>
            <input
              type="text"
              className={styles.input}
              value={username}
              onChange={(event) => setUsername(event.target.value)}
              placeholder="234-02141M"
              autoComplete="username"
            />
          </div>
          {fieldErrors.username && (
            <span className={styles.fieldError}>{fieldErrors.username}</span>
          )}
        </div>

        <div className={styles.field}>
          <label className={styles.label}>Password</label>
          <div className={styles.inputWrapper}>
            <span className={styles.icon} aria-hidden>
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <rect x="3" y="11" width="18" height="11" rx="2" ry="2" />
                <path d="M7 11V7a5 5 0 0 1 10 0v4" />
              </svg>
            </span>
            <input
              type="password"
              className={styles.input}
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              placeholder="••••••••"
              autoComplete="current-password"
            />
          </div>
          {fieldErrors.password && (
            <span className={styles.fieldError}>{fieldErrors.password}</span>
          )}
        </div>

        <button type="submit" disabled={loading} className={styles.submit}>
          {loading ? "Signing in..." : "LOGIN"}
        </button>
      </form>

      <button
        type="button"
        onClick={handleForgotPassword}
        className={styles.forgot}
      >
        Forgot password?
      </button>

      {showRegisterLink && (
        <p className={styles.registerPrompt}>
          Don&apos;t have an account?{' '}
          <Link
            to="/register"
            state={{ returnTo: "/login" }}
            className={styles.registerLink}
          >
            Create one
          </Link>
        </p>
      )}
    </div>
  );
};

export default LoginForm;
