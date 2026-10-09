import type {
  AccountStatus,
  PaginatedResponse,
  UserRole,
} from "./common.types";

export interface AccountCounts {
  totalStaffUsers: number;
  totalMarketVendorUsers: number;
  totalAdministrators: number;
  totalActiveAccounts: number;
}

export interface AccountSummary {
  id: number;
  role: UserRole;
  username: string;
  firstName: string;
  lastName: string;
  middleName: string | null;
  email: string | null;
  phoneNumber: string | null;
  profileUrl: string | null;
  status: AccountStatus;
}

export interface AccountFilters {
  offset: number;
  role?: UserRole;
  search?: string;
}

export type AccountPageResponse = PaginatedResponse<AccountSummary>;

export type StaffRole = Exclude<UserRole, "MarketVendor">;

export interface CreateStaffAccountRequest {
  role: StaffRole;
  firstName: string;
  middleName: string | null;
  lastName: string;
  dateOfBirth: string;
  email: string;
  phoneNumber: string;
  houseNumber: string;
  street: string;
  barangay: string;
  city: string;
}

export interface CreatedStaffAccount {
  id: number;
  username: string;
  role: StaffRole;
  email: string;
  status: "Active";
  mustChangePassword: true;
  emailSent: boolean;
  message: string;
}
