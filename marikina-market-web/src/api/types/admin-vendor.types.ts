import type { BusinessSnapshot } from "./ticket.types";
export interface AdminVendorSummary {
  vendorId: number;
  businessAccountNumber: string;
  vendorName: string;
  businessName: string;
  marketSectionName: string;
  type: string | number;
  complianceScore: number;
  warningCount: number;
  ticketCount: number;
}

export interface SaveBusinessRequest {
  businessAccountNumber: string;
  businessName: string;
  ownerFirstName: string;
  ownerLastName: string;
  houseNumber: string;
  street: string;
  barangay: string;
  city: string;
  phoneNumber: string | null;
  email: string | null;
  marketSectionId: number;
  businessType: "Public" | "Private" | "";
  stallNumber: string | null;
}

export interface BusinessRecord extends SaveBusinessRequest {
  id: number;
  marketSectionName: string | null;
  createdAt: string;
  status: string;
}

export type ComplianceScoreRange = "85-100" | "70-84" | "50-69" | "Below 50";

export interface AdminVendorActivity {
  ticketId: number;
  controlNumber: string | null;
  businessAccountNumber: string;
  activityTitle?: string | null;
  vendorName: string;
  type?: string | number | null;
  issuedAt: string;
}

export interface AdminVendorComplianceOverview {
  vendorsWithWarningsThisWeek: number;
  vendorsWithTicketsThisWeek: number;
  activities: AdminVendorActivity[];
}

export interface AdminPendingTicketSettlement {
  ticketId: number;
  controlNumber: string | null;
  businessAccountNumber: string | null;
  vendorName: string | null;
  marketSectionName: string;
  status: string | number;
  penaltyType: string | number | null;
  totalPaymentAmount: number | null;
  communityServiceHours: number | null;
  issuedAt: string;
  dueDate: string;
}

export interface AdminVendorPageResponse<T> {
  items: T[];
  hasMore: boolean;
  total: number | null;
}

export interface AdminVendorSummaryFilters {
  offset: number;
  search?: string;
  marketSectionId?: number;
  complianceScore?: ComplianceScoreRange;
}

export interface AdminVendorProfile {
  name: string;
  businessAccountNumber: string;
  businessName: string;
  phoneNumber: string | null;
  email: string | null;
  createdAt: string;
  lastViolationIssuedAt: string | null;
}

export interface AdminVendorComplianceScore {
  complianceScore: number;
  standing: string;
  violationFrequency: number;
  ticketsInWindow: number;
  violationFrequencyLevel: string;
  recency: number;
  daysSinceLastTicket: number | null;
  categorySeverity: number;
  averageSeverityPoints: number | null;
  categorySeverityLevel: string;
  penaltyPaymentHistory: number;
  paymentHistoryTickets: number;
  calculatedAt: string;
}

export interface AdminVendorInspection {
  businessSnapshot?: BusinessSnapshot | null;
  ticketId: number;
  controlNumber: string | null;
  type: string | number;
  issuedAt: string;
  ordinanceNumbers: string[];
  enforcerName: string;
}

export interface AdminVendorInspectionFilters {
  offset: number;
  search?: string;
  ticketType?: "Warning" | "Ticket";
  sortDirection: "asc" | "desc";
}

export interface AdminCommunityServiceLog {
  ticketId: number;
  controlNumber: string | null;
  businessAccountNumber: string | null;
  vendorName: string | null;
  completedHours: number;
  totalHours: number;
  lastUpdated: string;
  proofDocumentCount: number;
  status: string | number;
}

export interface AdminCommunityServiceLogFilters {
  offset: number;
  status?: string;
}

export interface AdminVendorInspectionNavigationState {
  vendorName: string;
  businessAccountNumber: string;
}
