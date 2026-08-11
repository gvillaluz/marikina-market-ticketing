import { createContext, ReactNode, useCallback, useContext, useMemo, useState } from 'react';
import { useAuthStore } from '@/store/store';
import type { User } from '@/features/auth/auth.types';
import type { LoginInput, RegisterInput } from '@/features/auth/auth.types';
import mockAdapter from '@/api/mock/mockAdapter';

interface AuthContextValue {
  user: User | null;
  isAuthenticated: boolean;
  isAdmin: boolean;
  isVendor: boolean;
  login: (input: LoginInput) => Promise<User | null>;
  register: (input: RegisterInput) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const { user, isAuthenticated, setAuth, logout: storeLogout } = useAuthStore();
  const [loading, setLoading] = useState(false);

const login = useCallback(
    async (input: LoginInput) => {
      setLoading(true);
      try {
        const res = await mockAdapter.login(input.email, input.password);
        setAuth(res.user, res.token);
        return res.user;
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
        const res = await mockAdapter.register(input);
        setAuth(res.user, res.token);
      } finally {
        setLoading(false);
      }
    },
    [setAuth],
  );

  const logout = useCallback(() => {
    storeLogout();
  }, [storeLogout]);

  const value = useMemo<AuthContextValue>(
    () => ({
      user,
      isAuthenticated,
      isAdmin: user?.role === 'admin',
      isVendor: user?.role === 'vendor',
      login,
      register,
      logout,
    }),
    [user, isAuthenticated, login, register, logout],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within an AuthProvider.');
  return ctx;
}

export default AuthContext;
