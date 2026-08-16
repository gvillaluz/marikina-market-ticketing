import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import type { User } from '@/features/auth/auth.types';

interface AuthState {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  setAuth: (user: User, token: string) => void;
  setUser: (user: User) => void;
  logout: () => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      user: null,
      token: null,
      isAuthenticated: false,
      setAuth: (user, token) => set({ user, token, isAuthenticated: true }),
      setUser: (user) => set({ user }),
      logout: () => set({ user: null, token: null, isAuthenticated: false }),
    }),
    {
      name: 'marikina-auth',
    },
  ),
);


// export const DEMO_USERS: User[] = [
//   {
//     id: 'u-admin',
//     name: 'Marikina Administrator',
//     email: 'admin@marikina.gov.ph',
//     role: 'admin',
//     avatar: 'MA',
//   },
//   {
//     id: 'u-vendor',
//     name: 'Juan Dela Cruz',
//     email: 'vendor@marikina.gov.ph',
//     role: 'vendor',
//     avatar: 'JD',
//   },
// ];
