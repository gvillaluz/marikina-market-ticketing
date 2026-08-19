import type { MarketSection} from '../../api/types/common.types';

export type InspectionType = 'warning' | 'ticket' | 'cleared'; // 'cleared' needs a Badge tone — see note below

export type Severity = 'low' | 'medium' | 'high';
export type PenaltyType = 'cashFine' | 'suspension' | 'revocation';
export type TicketStatus = 'pending' | 'paid' | 'overdue' | 'waived';

export interface OrdinanceViolation {
  ordinanceNo: string;
  ordinanceTitle: string;
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
  dateTime: string;
  location: string;
  violationCommitted: string;
  description?: string;

  severity?: Severity;
  penaltyType?: PenaltyType;
  dueDate?: string;
  totalFineDue?: number;
  ticketStatus?: TicketStatus;
  photoEvidenceUrl?: string;

  issuedBy: string;
  issuedByOrg: string;
  issuedTo: string;
  issuedAt: string;
}