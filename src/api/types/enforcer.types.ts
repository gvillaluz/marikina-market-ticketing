import { AccountStatus } from "./common.types";
import { TicketType } from "./ticket.types";

export interface EnforcerSummary {
  enforcerId: number;
  username: string;
  firstName: string;
  lastName: string;
  profileUrl: string;
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
  role: "MarketAdmin" | "HeadAdmin" | "Enforcer";
  hiredAt: Date;
  profileUrl: string;
  lastInspectionDate: Date;
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
  ticketId: number;
  controlNumber: string;
  issuedAt: Date;
  vendorFirstName: string;
  vendorLastName: string;
  stallNumber: string;
  marketSectionId: number;
  marketSectionName: string;
  type: TicketType;
  status: AccountStatus;
}
