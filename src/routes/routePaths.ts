import type { AuthAccess } from "@/api/types/common.types";

export const ROUTES = {
  login: "/login",
  adminLogin: "/admin/login",
  loginVerification: "/auth/verify-login",
  forgotPassword: (access: AuthAccess) =>
    access === "staff" ? "/admin/forgot-password" : "/forgot-password",
  register: "/register",
  changePassword: "/admin/change-password",
  dashboard: "/dashboard",
  inspections: "/inspections",
  tickets: "/tickets",
  enforcers: "/enforcers",
  adminVendors: "/admin/vendors",
  adminVendorRegistrations: "/admin/vendor-registrations",
  adminVendorRegistration: (id: string) =>
    `/admin/vendor-registrations/review/${id}`,
  adminVendorRegistrationApprove: (id: string) =>
    `/admin/vendor-registrations/review/${id}/approve`,
  adminVendorRegistrationDecline: (id: string) =>
    `/admin/vendor-registrations/review/${id}/decline`,
  adminVendorRegistrationInformation: (id: string) =>
    `/admin/vendor-registrations/review/${id}/request-information`,
  adminVendorInspections: (id: string) => `/admin/vendors/${id}/inspections`,
  enforcerPerformancePage: (id: string) => `/enforcer/performance/${id}`,
  analytics: "/analytics",
  ticketDetail: (id: string) => `/tickets/${id}`,
  vendors: "/vendors",
  vendorDetail: (id: string) => `/vendors/${id}`,
  vendorRegister: "/vendor/register",
  home: "/",
  systemConfiguration: "/system/configuration",
  marketSection: "/system/market-section",
  ordinance: "/system/ordinance",
  backups: "/configuration/backups",
  accounts: "/admin/accounts",
} as const;
