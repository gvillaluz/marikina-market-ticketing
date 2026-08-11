import { useState } from 'react';
import { useAuth } from '@/context/AuthContext';
import { useNavigate, useLocation } from 'react-router-dom';
import type { LoginInput } from '@/features/auth/auth.types';

export interface LoginFormValues {
  /** Either a username (vendor stall id / city id) or an email. */
  username: string;
  password: string;
}

/**
 * Maps the username field to the email the AuthContext/mock expects.
 * - If the user typed an email, keep it as-is.
 * - Otherwise treat it as a username; the mock auth layer currently
 *   authenticates via email, so we resolve catalog usernames next to the
 *   known demo accounts for local development.
 */
function resolveEmail(username: string): string {
  const trimmed = username.trim();
  if (trimmed.includes('@')) return trimmed;

  // Demo vendor / enforcer / admin username shortcuts
  if (trimmed.toLowerCase() === 'admin') return 'admin@marikina.gov.ph';
  if (trimmed.toLowerCase() === 'vendor' || /\d{3}-\d{5}/.test(trimmed)) return 'vendor@marikina.gov.ph';
  return trimmed;
}

interface UseLoginOptions {
  /** Restrict the login attempt to a specific role. */
  role?: 'admin' | 'enforcer' | 'vendor';
  /** Where to navigate after a successful login. Defaults to /dashboard. */
  redirectTo?: string;
}

export function useLogin(options: UseLoginOptions = {}) {
  const { login } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const { role, redirectTo } = options;
  const from = (location.state as { from?: { pathname: string } } | null)?.from?.pathname ?? redirectTo ?? '/dashboard';

  const submit = async (values: LoginFormValues) => {
    setLoading(true);
    setError(null);
    try {
      const input: LoginInput = {
        email: resolveEmail(values.username),
        password: values.password,
      };
      const authUser = await login(input);
      // If a role is required and the authenticated user does not match,
      // surface an error instead of navigating.
      if (role && authUser?.role !== role) {
        setError('This account does not have access to the requested area.');
        setLoading(false);
        return;
      }
      navigate(from, { replace: true });
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Login failed.');
    } finally {
      setLoading(false);
    }
  };

  return { submit, loading, error };
}

export default useLogin;
