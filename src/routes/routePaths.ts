export const ROUTES = {
  login: "/login",
  adminLogin: "/admin/login",
  forgotPassword: (role: "Admin" | "Vendor") =>
    role === "Admin" ? "/admin/forgot-password" : "/forgot-password",
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
  performance: "/performance",
  ticketDetail: (id: string) => `/tickets/${id}`,
  vendors: "/vendors",
  vendorDetail: (id: string) => `/vendors/${id}`,
  vendorRegister: "/vendor/register",
  penalties: "/penalties",
  compliance: "/compliance",
  home: "/",
  systemConfiguration: "/system/configuration",
  marketSection: "/system/market-section",
  ordinance: "/system/ordinance",
} as const;

export type RoutePath = (typeof ROUTES)[keyof typeof ROUTES];
