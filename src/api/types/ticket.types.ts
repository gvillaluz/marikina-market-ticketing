import type { MarketSection, OffenseLevel, RecordStatus, Severity, Status, PaginationSummary } from './common.types';

export type TicketType = 'violation' | 'complaint' | 'inspection' | 'renewal';
export type TicketSeverity = 'low' | 'medium' | 'high' | 'critical';

export interface InspectionRecord {
  id: string;
  controlNumber: string;
  type: 'warning' | 'ticket';
  enforcer: string;
  stallNo: string;
  tradeName: string;
  section: MarketSection;
  issuedAt: string;
  issued_at?: string;
  dateTime?: string;
  status: RecordStatus;
  enforcer_first_name?: string;
  enforcer_last_name?: string;
  stall_number?: string;
  business_name?: string;
  market_section_name?: string;
  market_section_id?: number;
}

export interface ViolationLine {
  id: string;
  ordinanceName: string;
  description: string;
  offenseLevel: OffenseLevel;
  amount: number;
}

export interface PenaltyDetails {
  severity: Severity;
  penaltyType: string;
  dueDate: string;
  totalFineDue: number;
}

interface BaseRecordDetail {
  id: string;
  controlNumber: string;
  stallNo: string;
  tradeName: string;
  violatorName: string;
  dateTime: string;
  location: string;
  violationCommitted: string;
  description: string;
  issuedByName: string;
  issuedByTitle: string;
  issuedByOffice: string;
  issuedToDate: string;
}

export interface WarningRecord extends BaseRecordDetail {
  type: 'warning';
  ordinanceNumber: string;
  ordinanceSeries: string;
  ordinanceCategory: string;
}

export interface TicketRecord extends BaseRecordDetail {
  type: 'ticket';
  status: RecordStatus;
  address: string;
  violations: ViolationLine[];
  penalty: PenaltyDetails;
  photoEvidenceUrl?: string;
  photoEvidenceUrls?: string[];
  settlementEvidenceUrls?: string[];
  enforcer?: string;
  enforcerName?: string;
  marketSection?: MarketSection | string;
  controlType?: string;
  appealsPeriod?: string;
  title?: string;
}

export interface TicketListResponse {
  items: TicketRecord[];
  total: number;
  page: number;
  pageSize: number;
  totalPages?: number;
  summary?: PaginationSummary;
}

type PrintColumn = 'controlNumber' | 'type' | 'issuedAt' | 'vendor' | 'status' | 'section' | 'severity';

export interface PrintConfigPayload {
  types: Array<'warning' | 'ticket'>;
  columns: PrintColumn[];
  startDate: string;
  endDate: string;
}

export interface ExportResult {
  fileUrl: string;
  fileName: string;
}

export interface CreateTicketPayload {
  stallNo: string;
  tradeName: string;
  violatorName: string;
  dateTime: string;
  location: string;
  address: string;
  violationCommitted: string;
  description: string;
  violations: Omit<ViolationLine, 'id'>[];
  penalty: Omit<PenaltyDetails, 'totalFineDue'>;
  photoEvidenceUrl?: string;
}

export interface Ticket {
  id: string;
  ticketNumber: string;
  type: TicketType;
  title: string;
  description: string;
  status: Status;
  severity: TicketSeverity;
  vendorId?: string;
  vendorName?: string;
  createdBy: string;
  createdAt: string;
  updatedAt: string;
  dueDate?: string;
  assignedTo?: string;
  amount?: number;
  location?: string;
}

export interface CreateTicketInput {
  type: TicketType;
  title: string;
  description: string;
  severity: TicketSeverity;
  vendorId?: string;
  location?: string;
  dueDate?: string;
}

export interface TicketHistoryEntry {
  id: string;
  ticketId: string;
  action: string;
  note?: string;
  performedBy: string;
  timestamp: string;
}