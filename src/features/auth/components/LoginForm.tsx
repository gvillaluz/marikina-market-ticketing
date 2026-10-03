import { FC, useState, FormEvent } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { ROUTES } from '@/routes/routePaths';
import { resolveLoginIdentifier } from '@/features/auth/auth.utils';
import type { LoginFormValues } from '@/features/auth/hooks/useLogin';

interface LoginFormProps {
  
  showRegisterLink?: boolean;
  
  role?: 'Admin' | 'Enforcer' | 'Vendor';
  submit: (values: LoginFormValues) => Promise<void>;
  loading: boolean;
  error: string | null;
}

const LoginForm: FC<LoginFormProps> = ({ showRegisterLink = true, role, submit, loading, error }) => {
  const navigate = useNavigate();
  const location = useLocation();
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [fieldErrors, setFieldErrors] = useState<{ username?: string; password?: string }>({});
  const passwordReset = (location.state as { passwordReset?: boolean } | null)?.passwordReset;
  const loginPath = role === 'Admin' ? ROUTES.adminLogin : ROUTES.login;

  const handleForgotPassword = () => {
    const nextStep = username.trim() ? 'options' : 'find-account';
    navigate(`${ROUTES.forgotPassword(role === 'Admin' ? 'Admin' : 'Vendor')}/${nextStep}`, {
      state: { username: username.trim() },
    });
  };

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    const errs: { username?: string; password?: string } = {};
    const isAdminLogin = role === 'Admin';

    if (!username.trim()) {
      errs.username = 'Enter your username.';
    } else if (!isAdminLogin && !resolveLoginIdentifier(username)) {
      errs.username = 'Enter your username or email.';
    }

    if (!password.trim()) {
      errs.password = 'Enter your password.';
    } else if (!isAdminLogin && password.length < 6) {
      errs.password = 'Password must be at least 6 characters.';
    }

    setFieldErrors(errs);
    if (Object.keys(errs).length > 0) return;

    await submit({ username, password });
  };

  return (
    <div>
      <h2 className="text-center font-mono font-bold text-2xl text-primary">LOGIN</h2>

      {passwordReset && (
        <div className="mt-4 rounded-md bg-green-50 px-4 py-3 text-sm text-green-700" role="status">
          Your password has been changed. Please log in with your new password.
        </div>
      )}

      {error && (
        <div className="mt-4 bg-red-50 text-red-700 px-4 py-3 rounded-md text-sm">
          {error}
        </div>
      )}

      <form className="mt-6 space-y-5" onSubmit={handleSubmit}>
        {/* Username */}
        <div>
          <label className="block text-xs font-semibold uppercase tracking-wider text-bodygray mb-1.5">
            Username
          </label>
          <div className="relative">
            <span className="absolute left-3 top-1/2 -translate-y-1/2 text-bodygray" aria-hidden>
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
                <circle cx="12" cy="7" r="4" />
              </svg>
            </span>
            <input
              type="text"
              className="w-full pl-10 pr-3 py-2.5 rounded-md border border-default text-sm focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              placeholder="234-02141M"
              autoComplete="username"
            />
          </div>
          {fieldErrors.username && <span className="text-xs text-red-600 mt-1 block">{fieldErrors.username}</span>}
        </div>

        {/* Password */}
        <div>
          <label className="block text-xs font-semibold uppercase tracking-wider text-bodygray mb-1.5">
            Password
          </label>
          <div className="relative">
            <span className="absolute left-3 top-1/2 -translate-y-1/2 text-bodygray" aria-hidden>
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <rect x="3" y="11" width="18" height="11" rx="2" ry="2" />
                <path d="M7 11V7a5 5 0 0 1 10 0v4" />
              </svg>
            </span>
            <input
              type="password"
              className="w-full pl-10 pr-3 py-2.5 rounded-md border border-default text-sm focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              autoComplete="current-password"
            />
          </div>
          {fieldErrors.password && <span className="text-xs text-red-600 mt-1 block">{fieldErrors.password}</span>}
        </div>

        <button
          type="submit"
          disabled={loading}
          className="w-full py-2.5 rounded-md bg-primary text-on-primary font-bold text-sm hover:bg-primary-hover hover:text-on-primary transition-colors disabled:opacity-60"
        >
          {loading ? 'Signing in…' : 'LOGIN'}
        </button>
      </form>

      <button
        type="button"
        onClick={handleForgotPassword}
        className="mt-4 block w-full text-center text-sm font-semibold text-primary underline"
      >
        Forgot password?
      </button>

      {showRegisterLink && (
        <p className="text-center text-sm text-bodygray mt-6">
          Don&apos;t have an account?{' '}
          <Link to="/register" className="underline font-semibold text-primary">
            Create one
          </Link>
        </p>
      )}
    </div>
  );
};

export default LoginForm;
