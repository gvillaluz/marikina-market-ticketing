
export interface ApiResponse<T> {
  success: boolean;
  message?: string;
  data: T;
}


export interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
  totalPages: number;
}


export interface PaginationParams {
  page?: number;
  pageSize?: number;
  search?: string;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
}


export type UserRole = 'admin' | 'vendor' | 'enforcer';

/** Status badges used across the app. */
export type Status = 'pending' | 'approved' | 'rejected' | 'resolved' | 'active' | 'suspended' | 'paid' | 'unpaid';
