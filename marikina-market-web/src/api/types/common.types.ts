export type AccountStatus = "Active" | "Inactive";

export interface ApiResponse<T> {
  success: boolean;
  message?: string;
  data: T;
}

export interface PaginationParams {
  page?: number;
  pageSize?: number;
  search?: string;
  sortBy?: string;
  sortOrder?: "asc" | "desc";
}

export type UserRole =
  "HeadAdmin" | "AdminOfficer" | "MarketEnforcer" | "MarketVendor";

export const USER_ROLES: readonly UserRole[] = [
  "HeadAdmin",
  "AdminOfficer",
  "MarketEnforcer",
  "MarketVendor",
];
export const ADMIN_ROLES: readonly UserRole[] = ["HeadAdmin", "AdminOfficer"];
export const STAFF_ROLES: readonly UserRole[] = [
  "HeadAdmin",
  "AdminOfficer",
  "MarketEnforcer",
];
export const HEAD_ADMIN_ROLES: readonly UserRole[] = ["HeadAdmin"];
export const USER_ROLE_LABELS: Record<UserRole, string> = {
  HeadAdmin: "Head Admin",
  AdminOfficer: "Admin Officer",
  MarketEnforcer: "Market Enforcer",
  MarketVendor: "Market Vendor",
};

export type Status =
  | "pending"
  | "approved"
  | "rejected"
  | "resolved"
  | "active"
  | "suspended"
  | "paid"
  | "unpaid";

export interface PaginatedResponse<T> {
  items: T[];
  hasMore: boolean;
  total: number;
}

export type InspectionType = "all" | "warning" | "ticket";

export type RecordStatus =
  | "Pending"
  | "Cleared"
  | "Contested"
  | "Paid"
  | "Overdue"
  | "InProgress"
  | "Waived";

export type OffenseLevel = "1st offense" | "2nd offense" | "3rd offense";

export type Severity = "Minor" | "Moderate" | "High";
