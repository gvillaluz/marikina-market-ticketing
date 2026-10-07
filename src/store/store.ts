import { create } from 'zustand';
import type { User } from '@/features/auth/auth.types';

interface AuthState {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  mustChangePassword: boolean;
  setAuth: (user: User, token: string) => void;
  setAccessToken: (token: string) => void;
  setMustChangePassword: (mustChangePassword: boolean) => void;
  setUser: (user: User) => void;
  logout: () => void;
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  token: null,
  isAuthenticated: false,
  mustChangePassword: false,
  setAuth: (user, token) => set({ user, token, isAuthenticated: true }),
  setAccessToken: (token) => set({ token }),
  setMustChangePassword: (mustChangePassword) => set({ mustChangePassword }),
  setUser: (user) => set({ user }),
  logout: () =>
    set({
      user: null,
      token: null,
      isAuthenticated: false,
      mustChangePassword: false,
    }),
}));
