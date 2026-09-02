
export const ROUTES = {
  login: '/login',
  adminLogin: '/admin/login',
  register: '/register',
  changePassword: "/admin/change-password",
  dashboard: '/dashboard',
  inspections: '/inspections',
  tickets: '/tickets',
  enforcers: '/enforcers',
  analytics: '/analytics',
  performance: '/performance',
  ticketDetail: (id: string) => `/tickets/${id}`,
  vendors: '/vendors',
  vendorDetail: (id: string) => `/vendors/${id}`,
  vendorRegister: '/vendor/register',
  penalties: '/penalties',
  compliance: '/compliance',
  home: '/',
} as const;

export type RoutePath = (typeof ROUTES)[keyof typeof ROUTES];
