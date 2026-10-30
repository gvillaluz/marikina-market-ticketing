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
  businessAccountNumber: string;
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
  businessAccountNumber: string;
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
  businessAccountNumber: string;
}

export interface VendorRegistrationStatusCounts {
  pendingReview: number;
  needsInformation: number;
  approved: number;
  rejected: number;
}

export interface VendorRegistrationSummary {
  registrationId: number;
  version: number;
  businessAccountNumber: string;
  businessName: string;
  vendorName: string;
  businessType: string | number;
  marketSectionName: string;
  stallNumber: string | null;
  requestedAt: string;
  status: string | number;
}

export interface VendorRegistrationDocument {
  documentType: string;
  fileName: string;
  contentType: string;
  size: number;
  url: string;
}

export interface VendorRegistrationDetails {
  registrationId: number;
  version: number;
  businessAccountNumber: string;
  businessName: string;
  natureOfBusiness: string;
  businessType: string | number;
  marketSectionName: string;
  stallNumber: string | null;
  firstName: string;
  middleName: string | null;
  lastName: string;
  dateOfBirth: string;
  age: number;
  governmentIdType: string | number | null;
  governmentIdNumber: string | null;
  phoneNumber: string;
  email: string;
  houseNumber: string;
  street: string;
  barangay: string;
  city: string;
  status: string | number;
  requestedAt: string;
  reviewedAt: string | null;
  reviewerName: string | null;
  remarksOrReason: string | null;
  reviewReason: string | null;
  reviewRemarks: string | null;
  documents: VendorRegistrationDocument[] | null;
}

export interface RegistrationApprovalRequest {
  vendorRegistrationId: number;
  version: number;
}

export interface RegistrationDeclineRequest extends RegistrationApprovalRequest {
  reviewReason: string;
  reviewRemarks: string;
}

export interface RegistrationApprovalResponse {
  registrationId: number;
  vendorStatus: "Active" | "Inactive";
  reviewedAt: string;
  emailSent: boolean;
  userId: number;
  vendorId: number;
  firstName: string;
  middleName: string;
  lastName: string;
  businessName: string;
  marketSectionId: number;
  marketSectionName: string;
  adminId: number;
  status: "Approved";
  createdAt: string;
  version: number;
}

export interface RegistrationDeclinedResponse {
  status: "Rejected" | "NeedsInformation";
  emailSent: boolean;
  registrationId: number;
  firstName: string;
  middleName: string | null;
  lastName: string;
  businessName: string;
  reviewReason: string;
  reviewRemarks: string;
  adminId: number;
  reviewedAt: string;
  version: number;
}

export interface VendorRegistrationFilters {
  offset: number;
  status?: string;
  businessType?: string;
}

export interface AdminRegisterVendorRequest {
  firstName: string;
  middleName: string;
  lastName: string;
  dateOfBirth: string;
  phoneNumber: string;
  houseNumber: string;
  street: string;
  barangay: string;
  city: string;
  businessName: string;
  businessAccountNumber: string;
  natureOfBusiness: string;
  marketSectionId: number;
  stallNumber: string;
  businessType: string;
  username: string;
  email: string;
  password: string;
  confirmPassword: string;
}

export interface RegistrationApproval {
  userId: number;
  vendorId: number;
  firstName: string;
  middleName: string;
  lastName: string;
  businessName: string;
  marketSectionId: number;
  marketSectionName: string;
  adminId: number;
  status: string | number;
  createdAt: string;
  version: number;
}
