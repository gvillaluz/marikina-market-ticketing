import { useState } from 'react';
import { useAuth } from '@/context/AuthContext';
import { useNavigate, useLocation } from 'react-router-dom';
import { ROUTES } from '@/routes/routePaths';
import type { LoginInput } from '@/features/auth/auth.types';
import { jwtDecode } from 'jwt-decode';

export interface LoginFormValues {
  username: string;
  password: string;
}

export function resolveLoginIdentifier(username: string): string | null {
  const trimmed = username.trim();
  if (!trimmed) return null;

  if (trimmed.includes('@')) {
    const isEmail = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(trimmed);
    return isEmail ? trimmed : null;
  }

  if (trimmed.toLowerCase() === 'admin') return 'admin@marikina.gov.ph';
  if (trimmed.toLowerCase() === 'vendor' || /^\d{3}-\d{5}[A-Za-z]?$/.test(trimmed)) {
    return 'vendor@marikina.gov.ph';
  }

  return null;
}

interface UseLoginOptions {
  role?: 'Admin' | 'Enforcer' | 'Vendor';
  redirectTo?: string;
}

export function useLogin(options: UseLoginOptions = {}) {
  const { login } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const { role, redirectTo } = options;
  const from = (location.state as { from?: { pathname: string } } | null)?.from?.pathname ?? redirectTo ?? ROUTES.dashboard;

  const submit = async (values: LoginFormValues) => {
    setLoading(true);
    setError(null);
    try {
      const input: LoginInput = {
        username: values.username.trim(),
        password: values.password,
      };

      const { user, mustChangePassword, } = await login(input);
      if (!user.role) {
        setError('not access');
        setLoading(false);
        return;
      }
      
      console.log('Redirecting to:', from);
      navigate(from, { replace: true });
      console.log('Navigation complete'); 
    } catch (err) {
      console.log('Login error:', err);
      setError(err instanceof Error ? err.message : 'Login failed.');
    } finally {
      setLoading(false);
    }
  };

  return { submit, loading, error };
}

export default useLogin;