
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
