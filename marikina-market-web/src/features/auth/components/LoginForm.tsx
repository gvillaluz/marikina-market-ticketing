import type { FC } from "react";
import {
  Eye,
  EyeOff,
  LoaderCircle,
  LockKeyhole,
  Mail,
  UserRound,
} from "lucide-react";
import Button from "@/components/ui/Button";
import type { LoginFormValues } from "../hooks/useLogin";
import { useCapsLock } from "../hooks/useCapsLock";
import { useLoginForm } from "../hooks/useLoginForm";
import CapsLockNote from "./CapsLockNote";
import styles from "./LoginForm.module.css";

interface LoginFormProps {
  submit: (values: LoginFormValues) => Promise<void>;
  loading: boolean;
  error: string | null;
}
const LoginForm: FC<LoginFormProps> = ({ submit, loading, error }) => {
  const model = useLoginForm(submit, loading);
  const caps = useCapsLock();
  return (
    <div className={styles.formWrapper}>
      <h2 className={styles.heading}>Log in</h2>
      <p className={styles.intro}>
        Administrator access. Use your staff username and password.
      </p>
      {model.passwordReset && (
        <div className={styles.successMessage} role="status">
          Your password has been changed. Please log in with your new password.
        </div>
      )}
      {error && (
        <div className={styles.errorMessage} role="alert">
          {error}
        </div>
      )}
      <form
        className={styles.form}
        onSubmit={model.handleSubmit}
        aria-busy={loading}
      >
        <div className={styles.field}>
          <label className={styles.label} htmlFor="login-username">
            Username
          </label>
          <div className={styles.inputWrapper}>
            <UserRound className={styles.icon} size={18} aria-hidden="true" />
            <input
              id="login-username"
              ref={model.usernameRef}
              type="text"
              className={styles.input}
              value={model.username}
              onChange={(event) => model.changeUsername(event.target.value)}
              placeholder="Enter your username"
              autoComplete="username"
              maxLength={200}
              disabled={loading}
              aria-invalid={Boolean(model.fieldErrors.username)}
              aria-describedby={
                model.fieldErrors.username ? "login-username-error" : undefined
              }
            />
          </div>
          {model.fieldErrors.username && (
            <span
              id="login-username-error"
              className={styles.fieldError}
              role="alert"
            >
              {model.fieldErrors.username}
            </span>
          )}
        </div>
        <div className={styles.field}>
          <div className={styles.labelRow}>
            <label className={styles.label} htmlFor="login-password">
              Password
            </label>
            <button
              type="button"
              onClick={model.forgotPassword}
              disabled={loading}
              className={styles.forgot}
            >
              Forgot password?
            </button>
          </div>
          <div className={styles.inputWrapper}>
            <LockKeyhole className={styles.icon} size={18} aria-hidden="true" />
            <input
              id="login-password"
              ref={model.passwordRef}
              type={model.showPassword ? "text" : "password"}
              className={`${styles.input} ${styles.password}`}
              value={model.password}
              onChange={(event) => model.changePassword(event.target.value)}
              placeholder="Enter your password"
              autoComplete="current-password"
              maxLength={128}
              disabled={loading}
              aria-invalid={Boolean(model.fieldErrors.password)}
              aria-describedby={
                [
                  model.fieldErrors.password ? "login-password-error" : "",
                  caps.field === "login-password" ? "login-password-caps" : "",
                ]
                  .filter(Boolean)
                  .join(" ") || undefined
              }
              {...caps.bind("login-password")}
            />
            <Button
              className={styles.passwordToggle}
              variant="ghost"
              size="sm"
              type="button"
              onClick={model.togglePassword}
              disabled={loading}
              aria-label={
                model.showPassword ? "Hide password" : "Show password"
              }
              aria-pressed={model.showPassword}
            >
              {model.showPassword ? (
                <EyeOff size={16} aria-hidden="true" />
              ) : (
                <Eye size={16} aria-hidden="true" />
              )}
            </Button>
          </div>
          {caps.field === "login-password" && (
            <CapsLockNote id="login-password-caps" />
          )}
          {model.fieldErrors.password && (
            <span
              id="login-password-error"
              className={styles.fieldError}
              role="alert"
            >
              {model.fieldErrors.password}
            </span>
          )}
        </div>
        <button type="submit" disabled={loading} className={styles.submit}>
          {loading && (
            <LoaderCircle
              className={styles.spinner}
              size={16}
              aria-hidden="true"
            />
          )}
          {loading ? "Sending code…" : "Log in"}
        </button>
      </form>
      <p className={styles.codeHint}>
        <Mail className={styles.codeHintIcon} size={18} aria-hidden="true" />
        Next, we email you a 6-digit code to finish logging in.
      </p>
    </div>
  );
};
export default LoginForm;
