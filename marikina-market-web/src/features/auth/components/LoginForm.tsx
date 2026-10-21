import type { AuthAccess } from "@/api/types/common.types";
import type { FC } from "react";
import { Link } from "react-router-dom";
import {
  Eye,
  EyeOff,
  LoaderCircle,
  LockKeyhole,
  UserRound,
} from "lucide-react";
import Button from "@/components/ui/Button";
import type { LoginFormValues } from "../hooks/useLogin";
import { useLoginForm } from "../hooks/useLoginForm";
import styles from "./LoginForm.module.css";

interface LoginFormProps {
  showRegisterLink?: boolean;
  access?: AuthAccess;
  submit: (values: LoginFormValues) => Promise<void>;
  loading: boolean;
  error: string | null;
}
const LoginForm: FC<LoginFormProps> = ({
  showRegisterLink = true,
  access,
  submit,
  loading,
  error,
}) => {
  const model = useLoginForm(access, submit, loading);
  return (
    <div className={styles.formWrapper}>
      <h2 className={styles.heading}>LOGIN</h2>
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
              placeholder={
                access === "staff"
                  ? "Enter your username"
                  : "Enter your username or email"
              }
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
          <label className={styles.label} htmlFor="login-password">
            Password
          </label>
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
                model.fieldErrors.password ? "login-password-error" : undefined
              }
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
          {loading ? "Sending code…" : "LOGIN"}
        </button>
      </form>
      <button
        type="button"
        onClick={model.forgotPassword}
        disabled={loading}
        className={styles.forgot}
      >
        Forgot password?
      </button>
      {showRegisterLink && (
        <p className={styles.registerPrompt}>
          Don&apos;t have an account?{" "}
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
