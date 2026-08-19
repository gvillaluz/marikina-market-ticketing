import type { TicketSeverity, TicketType } from '@/api/types/ticket.types';
import type { VendorCategory } from '@/api/types/vendor.types';
import type { Status } from '@/api/types/common.types';

/** Barangays of Marikina City. */
export const MARIKINA_BARANGAYS = [
  'Barangka',
  'Calumpang',
  'Concepcion Dos',
  'Concepcion Uno',
  'Fortune',
  'Industrial Valley',
  'Jesus De La Peña',
  'Malanday',
  'Marikina Heights',
  'Nangka',
  'Parang',
  'San Roque',
  'Santa Elena',
  'Santo Niño',
  'Tañong',
];

export const VENDOR_CATEGORIES: VendorCategory[] = [
  'retail',
  'food',
  'services',
  'manufacturing',
  'construction',
  'other',
];

export const TICKET_TYPES: TicketType[] = [
  'violation',
  'complaint',
  'inspection',
  'renewal',
];

export const TICKET_SEVERITIES: TicketSeverity[] = [
  'low',
  'medium',
  'high',
  'critical',
];

export const STATUS_LABELS: Record<Status, string> = {
  pending: 'Pending',
  approved: 'Approved',
  rejected: 'Rejected',
  resolved: 'Resolved',
  active: 'Active',
  suspended: 'Suspended',
  paid: 'Paid',
  unpaid: 'Unpaid',
};

export const TICKET_TYPE_LABELS: Record<TicketType, string> = {
  violation: 'Violation',
  complaint: 'Complaint',
  inspection: 'Inspection',
  renewal: 'Renewal',
};

export const SEVERITY_LABELS: Record<TicketSeverity, string> = {
  low: 'Low',
  medium: 'Medium',
  high: 'High',
  critical: 'Critical',
};

export const CATEGORY_LABELS: Record<VendorCategory, string> = {
  retail: 'Retail',
  food: 'Food & Beverage',
  services: 'Services',
  manufacturing: 'Manufacturing',
  construction: 'Construction',
  other: 'Other',
};

export const APP_CONSTANTS = {
  message: 'Marikina Ticketing System',
  city: 'Marikina City',
  province: 'Metro Manila, Philippines',
  currency: '₱',
};

export const INSPECTION_TYPE_OPTIONS = [
  { value: 'all', label: 'All Records' },
  { value: 'warning', label: 'Warning' },
  { value: 'ticket', label: 'Ticket' },
] as const;

export const PRINT_COLUMN_OPTIONS = [
  { value: 'controlNumber', label: 'Control #' },
  { value: 'vendor', label: 'Vendor' },
  { value: 'section', label: 'Section' },
  { value: 'type', label: 'Type' },
  { value: 'status', label: 'Status' },
  { value: 'issuedAt', label: 'Issued At' },
  { value: 'severity', label: 'Severity' },
] as const;
