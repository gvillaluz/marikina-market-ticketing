import type {
  BusinessSnapshot,
  PenaltyType,
  TicketCategories,
} from "./ticket.types";
import type { UserRole } from "./common.types";
import { AccountStatus } from "./common.types";

export interface EnforcerReportTotals {
  warnings: number;
  tickets: number;
  totalRecords: number;
  settledTickets: number;
  openTickets: number;
  finesCharged: number;
  finesSettled: number;
}

export interface EnforcerReportRow extends EnforcerReportTotals {
  enforcerId: number;
  username: string;
  firstName: string;
  lastName: string;
  status: AccountStatus;
  daysWithRecords: number;
  lastRecordAt: string | null;
}

export interface EnforcerReport {
  dateRange: { from: string; to: string };
  enforcers: EnforcerReportRow[];
  totals: EnforcerReportTotals;
}

export interface EnforcerRecordCount {
  warnings: number;
  tickets: number;
  total: number;
}

/** A null penalty type means none was recorded on the ticket. */
export interface EnforcerPenaltyKind {
  penaltyType: PenaltyType | null;
  tickets: number;
  settledTickets: number;
  openTickets: number;
  finesCharged: number;
}

/** A null category means the record has no ordinance recorded. */
export interface EnforcerViolationType extends EnforcerRecordCount {
  category: TicketCategories | null;
}

export interface EnforcerMarketStreet extends EnforcerRecordCount {
  marketSectionId: number;
  marketSectionName: string;
}

/** A Philippine calendar day (YYYY-MM-DD). */
export interface EnforcerReportDate extends EnforcerRecordCount {
  date: string;
}

export interface EnforcerActivityReport {
  dateRange: { from: string; to: string };
  enforcer: EnforcerReportRow;
  penaltyKinds: EnforcerPenaltyKind[];
  violationTypes: EnforcerViolationType[];
  marketStreets: EnforcerMarketStreet[];
  days: EnforcerReportDate[];
}

export interface EnforcerSummary {
  enforcerId: number;
  username: string;
  firstName: string;
  lastName: string;
  profileUrl: string | null;
  status: AccountStatus;
  warningViolationCount: number;
  ticketViolationCount: number;
}

export interface TopIssuer {
  enforcerId: number;
  enforcerName: string;
  totalTickets: number;
}

export interface EnforcerActivityData {
  totalTicketCount: number;
  totalWarningCount: number;
  averageTicketPerDay: number;
  averageWarningPerDay: number;
  topEnforcers: TopIssuer[];
}

export interface MonthlyInspection {
  month: number;
  totalIssuedTickets: number;
}

export interface EnforcerProfile {
  userId: number;
  username: string;
  firstName: string;
  lastName: string;
  middleName?: string;
  phoneNumber: string;
  email: string;
  status: AccountStatus;
  role: UserRole;
  hiredAt: Date;
  profileUrl: string;
  lastInspectionDate: Date | null;
}

export interface EnforcerPerformanceData {
  enforcerId: number;
  totalInspections: number;
  resolutionRate: number;
  warningRatio: number;
  ticketRatio: number;
  monthlyInspections: MonthlyInspection[];
}

export interface InspectionHistorySummary {
  businessSnapshot?: BusinessSnapshot | null;
  ticketId: number;
  controlNumber: string | null;
  issuedAt: Date;
  vendorId: number | null;
  vendorFirstName: string | null;
  vendorLastName: string | null;
  stallNumber: string | null;
  marketSectionId: number;
  marketSectionName: string;
  type: "Ticket" | "Warning";
  status: AccountStatus;
}
