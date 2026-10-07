import { useState } from 'react';
import { useAuth } from '@/context/AuthContext';
import { useNavigate, useLocation } from 'react-router-dom';
import { ROUTES } from '@/routes/routePaths';
import type { LoginInput } from '@/features/auth/auth.types';
import { resolveLoginIdentifier } from '@/features/auth/auth.utils';
import { getApiErrorMessage } from '@/utils/apiErrors';

export interface LoginFormValues {
  username: string;
  password: string;
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
      setError(getApiErrorMessage(err, 'Login failed.'));
    } finally {
      setLoading(false);
    }
  };

  return { submit, loading, error };
}

export default useLogin;