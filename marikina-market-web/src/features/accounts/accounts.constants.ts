import { USER_ROLE_LABELS, type UserRole } from "@/api/types/common.types";

export const ACCOUNT_ROLE_LABELS = USER_ROLE_LABELS;

export const ACCOUNT_TABS: { label: string; role: UserRole | "all" }[] = [
  { label: "All", role: "all" },
  { label: "Head Admin", role: "HeadAdmin" },
  { label: "Admin Officers", role: "AdminOfficer" },
  { label: "Market Enforcers", role: "MarketEnforcer" },
  { label: "Market Vendors", role: "MarketVendor" },
];
