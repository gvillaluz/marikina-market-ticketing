import { TicketSummary } from "./ticket.types";

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

export type UserRole = 'Admin' | 'Vendor' | 'Enforcer';

export type Status = 'pending' | 'approved' | 'rejected' | 'resolved' | 'active' | 'suspended' | 'paid' | 'unpaid';

export interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
}

export interface ApiError {
  status: number;
  message: string;
  code?: string;
  details?: unknown;
}

export type MarketSection =
  | 'fishAndSeafood'
  | 'meat'
  | 'dryGoods'
  | 'vegetable'
  | 'groceries'
  | 'eatery'
  | 'specialStalls'
  | 'miscellaneous';

export const MARKET_SECTION_LABELS: Record<MarketSection, string> = {
  fishAndSeafood: 'Fish and Seafood Section',
  meat: 'Meat Section',
  dryGoods: 'Dry Goods Section',
  vegetable: 'Vegetable Section',
  groceries: 'Groceries Section',
  eatery: 'Eatery Section',
  specialStalls: 'Special Stalls',
  miscellaneous: 'Miscellaneous Section',
};

export const MARKET_SECTION_IDS: Record<MarketSection, number> = {
  fishAndSeafood: 1,
  meat: 2,
  dryGoods: 3,
  vegetable: 4,
  groceries: 5,
  eatery: 6,
  specialStalls: 7,
  miscellaneous: 8,
};

export type InspectionType = 'all' | 'warning' | 'ticket';

export type RecordStatus = 'Pending' | 'Cleared' | 'Contested' | 'Paid' | 'Overdue' | 'Waived';

export type OffenseLevel = '1st offense' | '2nd offense' | '3rd offense';

export type Severity = 'Minor' | 'Moderate' | 'High';

export interface PaginationSummary {
  totalTickets: number;
  pendingPayments: number;
  resolvedViolations: number;
  resolutionRate: number;
  criticalSeverities: number;
  totalTicketsChange?: number;
  pendingPaymentsChange?: number;
  criticalSeveritiesChange?: number;
}

export interface TicketPagination {
  tickets: TicketSummary[],
  total: number,
  page: number
}