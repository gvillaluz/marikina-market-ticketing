/** Generic API response wrapper. */
export interface ApiResponse<T> {
  success: boolean;
  message?: string;
  data: T;
}

/** Paginated collection response. */
export interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
  totalPages: number;
}

/** Common pagination request params. */
export interface PaginationParams {
  page?: number;
  pageSize?: number;
  search?: string;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
}

/** Supported user roles. */
export type UserRole = 'admin' | 'vendor' | 'enforcer';

/** Status badges used across the app. */
export type Status = 'pending' | 'approved' | 'rejected' | 'resolved' | 'active' | 'suspended' | 'paid' | 'unpaid';
