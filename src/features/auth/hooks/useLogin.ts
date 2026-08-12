import { useState } from 'react';
import { useAuth } from '@/context/AuthContext';
import { useNavigate, useLocation } from 'react-router-dom';
import type { LoginInput } from '@/features/auth/auth.types';

export interface LoginFormValues {
  
  username: string;
  password: string;
}


function resolveEmail(username: string): string {
  const trimmed = username.trim();
  if (trimmed.includes('@')) return trimmed;

 
  if (trimmed.toLowerCase() === 'admin') return 'admin@marikina.gov.ph';
  if (trimmed.toLowerCase() === 'vendor' || /\d{3}-\d{5}/.test(trimmed)) return 'vendor@marikina.gov.ph';
  return trimmed;
}

interface UseLoginOptions {
 
  role?: 'admin' | 'enforcer' | 'vendor';
 
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
