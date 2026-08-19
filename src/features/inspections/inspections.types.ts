export type MarketSection =
  | 'Fish and Seafood Section'
  | 'Meat Section'
  | 'Dry Goods Section'
  | 'Vegetable Section'
  | 'Groceries Section'
  | 'Eatery Section'
  | 'Special Stalls'
  | 'Miscellaneous Section';

export type InspectionType = 'Warning' | 'Ticket' | 'Cleared';

export type Severity = 'Low' | 'Medium' | 'High';

export type PenaltyType = 'CashFine' | 'Suspension' | 'Revocation';

export type TicketStatus = 'Pending' | 'Paid' | 'Overdue' | 'Waived';

export interface OrdinanceViolation {
  ordinanceNo: string;      // "Ord. No. 145, Series of 2006"
  ordinanceTitle: string;   // "Peace & Order Code"
  offenseCount: '1st offense' | '2nd offense' | '3rd offense';
  fineAmount: number;
}

export interface InspectionRecord {
  id: string;
  controlNumber: string;
  type: InspectionType;

  enforcer: string;
  stallNo: string;
  tradeName: string;
  section: MarketSection;

  violatorName: string;
  violatorAddress?: string;

  ordinances: OrdinanceViolation[];
  dateTime: string;              // ISO string
  location: string;
  violationCommitted: string;    // e.g. "Obstruction, Noise"
  description?: string;

  // Ticket-only
  severity?: Severity;
  penaltyType?: PenaltyType;
  dueDate?: string;
  totalFineDue?: number;
  ticketStatus?: TicketStatus;
  photoEvidenceUrl?: string;

  issuedBy: string;              // "Market Officer"
  issuedByOrg: string;           // "Marikina City Public Market"
  issuedTo: string;              // "Market Vendor"
  issuedAt: string;               // ISO string, shown in table
}

export interface InspectionFilters {
  search: string;
  type: 'All' | InspectionType;
  section: 'All' | MarketSection;
  startDate?: string;
  endDate?: string;
}

export interface ExportConfig {
  types: InspectionType[];
  columns: Array<'controlNumber' | 'type' | 'issuedAt' | 'vendor' | 'status' | 'section' | 'severity'>;
  format: 'csv' | 'xlsx' | 'pdf';
  startDate?: string;
  endDate?: string;
}