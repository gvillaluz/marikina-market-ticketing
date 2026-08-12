import client from '@/api/client';
import type { AuthResponse, LoginInput, RegisterInput } from '@/features/auth/auth.types';
import type { ApiResponse } from '@/api/types/common.types';

export const authApi = {
  async login(input: LoginInput): Promise<AuthResponse> {
    const { data } = await client.post<ApiResponse<AuthResponse>>('/auth/login', input);
    return data.data;
  },

  async register(input: RegisterInput): Promise<AuthResponse> {
    const { data } = await client.post<ApiResponse<AuthResponse>>('/auth/register', input);
    return data.data;
  },

  async getCurrentUser(): Promise<AuthResponse['user']> {
    const { data } = await client.get<ApiResponse<AuthResponse['user']>>('/auth/me');
    return data.data;
  },

  async logout(): Promise<void> {
    await client.post('/auth/logout');
  },
};
