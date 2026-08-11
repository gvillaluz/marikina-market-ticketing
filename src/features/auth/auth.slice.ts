/**
 * Auth slice placeholder.
 * The project currently uses Zustand for auth state (see src/store/store.ts).
 * If migrating to Redux Toolkit, the auth state reducer and actions would live here.
 */
export type { User, LoginInput, RegisterInput, AuthResponse } from '@/features/auth/auth.types';

export interface AuthSliceState {
  user: import('@/features/auth/auth.types').User | null;
  token: string | null;
  isAuthenticated: boolean;
}

export const initialAuthState: AuthSliceState = {
  user: null,
  token: null,
  isAuthenticated: false,
};
