import client from '@/api/client';
import type { AuthResponse, LoginInput, RegisterInput, User } from '@/features/auth/auth.types';

export interface MandatoryChangePasswordInput {
  current_password: string;
  new_password: string;
  confirm_new_password: string;
}

export const authApi = {
  async login(input: LoginInput): Promise<AuthResponse> {
    const { data } = await client.post<AuthResponse>('/auth/login', input);
    return data;
  },

  async register(input: RegisterInput): Promise<AuthResponse> {
    const { data } = await client.post<AuthResponse>('/auth/register', input);
    return data;
  },

 async getMe(token: string): Promise<User> {
  const { data } = await client.post<User>('/auth/me', undefined, {
    headers: { Authorization: `Bearer ${token}` },
  });
  return data;
},

  async logout(): Promise<void> {
    await client.post('/auth/logout');
  },

  async mandatoryChangePassword(input: MandatoryChangePasswordInput): Promise<void> {
    await client.post('/auth/mandatory-change-password', input);
  },
};