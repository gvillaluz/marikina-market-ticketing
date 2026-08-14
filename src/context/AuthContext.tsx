import { createContext, ReactNode, useCallback, useContext, useMemo, useState } from 'react';
import { useAuthStore } from '@/store/store';
import type { User, LoginInput, RegisterInput } from '@/features/auth/auth.types';
import { authApi } from '@/api/endpoints/auth.api';

interface AuthContextValue {
  user: User | null;
  isAuthenticated: boolean;
  isAdmin: boolean;
  isVendor: boolean;
  mustChangePassword: boolean;
  login: (input: LoginInput) => Promise<{ user: User; mustChangePassword: boolean }>;
  register: (input: RegisterInput) => Promise<void>;
  logout: () => void;
  clearMustChangePassword: () => void;
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const { user, isAuthenticated, setAuth, logout: storeLogout } = useAuthStore();
  const [loading, setLoading] = useState(false);
  const [mustChangePassword, setMustChangePassword] = useState(false);

  const login = useCallback(
  async (input: LoginInput) => {
    setLoading(true);
    try {
      const res = await authApi.login(input);
      const profile = await authApi.getMe(res.access_token);
      setAuth(profile, res.access_token);
      setMustChangePassword(res.must_change_password);

      return { user: profile, mustChangePassword: res.must_change_password };
    } finally {
      setLoading(false);
    }
  },
  [setAuth],
);

const register = useCallback(
  async (input: RegisterInput) => {
    setLoading(true);
    try {
      const res = await authApi.register(input);
      const profile = await authApi.getMe(res.access_token);
      setAuth(profile, res.access_token);
      setMustChangePassword(res.must_change_password);
    } finally {
      setLoading(false);
    }
  },
  [setAuth],
);

  const logout = useCallback(() => {
    setMustChangePassword(false);
    storeLogout();
  }, [storeLogout]);

  const clearMustChangePassword = useCallback(() => {
    setMustChangePassword(false);
  }, []);

  const value = useMemo<AuthContextValue>(
    () => ({
      user,
      isAuthenticated,
      isAdmin: user?.role === 'admin',
      isVendor: user?.role === 'vendor',
      mustChangePassword,
      login,
      register,
      logout,
      clearMustChangePassword,
    }),
    [user, isAuthenticated, mustChangePassword, login, register, logout, clearMustChangePassword],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within an AuthProvider.');
  return ctx;
}

export default AuthContext;