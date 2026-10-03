export interface AdminVendorSummary {
  vendorId: number;
  businessId: string;
  vendorName: string;
  marketSectionName: string;
  type: string | number;
  complianceScore: number;
  warningCount: number;
  ticketCount: number;
}

export type ComplianceScoreRange =
  | "85-100"
  | "70-84"
  | "50-69"
  | "Below 50";

export interface AdminVendorActivity {
  ticketId: number;
  controlNumber: string | null;
  businessId: string;
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
  businessId: string;
  vendorName: string;
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
  username: string | null;
  phoneNumber: string | null;
  email: string | null;
  accountCreatedAt: string;
  role: string | number;
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
  businessId: string;
  vendorName: string;
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
  businessId: string;
}

export interface VendorRegistrationStatusCounts {
  pendingReview: number;
  needsInformation: number;
  approved: number;
  rejected: number;
}

export interface VendorRegistrationSummary {
  registrationId: number;
  businessId: string;
  businessName: string;
  vendorName: string;
  vendorType: string | number;
  marketSectionName: string;
  stallNumber: string | null;
  requestedAt: string;
  status: string | number;
}

export interface VendorRegistrationFilters {
  offset: number;
  status?: string;
  vendorType?: string;
}
