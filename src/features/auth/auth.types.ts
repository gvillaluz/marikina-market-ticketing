import type { UserRole } from '@/api/types/common.types';

export interface User {
  id: string;
  name: string;
  email: string;
  role: UserRole;
  avatar?: string;
}

export interface LoginInput {
  username: string;
  password: string;
}

export interface RegisterInput {
  name: string;
  email: string;
  password: string;
  role: UserRole;
}

export interface AuthResponse {
  user: User;
  must_change_password: boolean;  
  access_token: string;
}

export interface User {
  id: string;
  username: string;
  role: 'admin' | 'enforcer' | 'vendor';
}