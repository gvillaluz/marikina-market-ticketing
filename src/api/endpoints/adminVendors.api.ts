import client from "@/api/client";
import type {
  AdminPendingTicketSettlement,
  AdminCommunityServiceLog,
  AdminCommunityServiceLogFilters,
  AdminVendorComplianceOverview,
  AdminVendorComplianceScore,
  AdminVendorInspection,
  AdminVendorInspectionFilters,
  AdminVendorProfile,
  AdminVendorPageResponse,
  AdminVendorSummary,
  AdminVendorSummaryFilters,
  VendorRegistrationFilters,
  VendorRegistrationStatusCounts,
  VendorRegistrationSummary,
  VendorRegistrationDetails,
  VendorRegistrationDocument,
  AdminRegisterVendorRequest,
  RegistrationApproval,
  RegistrationApprovalRequest,
  RegistrationApprovalResponse,
  RegistrationDeclineRequest,
  RegistrationDeclinedResponse,
} from "@/api/types/admin-vendor.types";

export const adminVendorsApi = {
  async list(
    filters: AdminVendorSummaryFilters,
  ): Promise<AdminVendorPageResponse<AdminVendorSummary>> {
    const { data } = await client.get<
      AdminVendorPageResponse<AdminVendorSummary>
    >("/admin/vendors", { params: filters });
    return data;
  },

  async getComplianceOverview(): Promise<AdminVendorComplianceOverview> {
    const { data } = await client.get<AdminVendorComplianceOverview>(
      "/admin/vendors/compliance-overview",
    );
    return data;
  },

  async getPendingSettlements(
    offset: number,
  ): Promise<AdminVendorPageResponse<AdminPendingTicketSettlement>> {
    const { data } = await client.get<
      AdminVendorPageResponse<AdminPendingTicketSettlement>
    >("/admin/vendors/pending-settlements", { params: { offset } });
    return data;
  },

  async getCommunityServiceLogs(
    filters: AdminCommunityServiceLogFilters,
  ): Promise<AdminVendorPageResponse<AdminCommunityServiceLog>> {
    const { data } = await client.get<
      AdminVendorPageResponse<AdminCommunityServiceLog>
    >("/admin/vendors/community-service-logs", { params: filters });
    return data;
  },

  async getProfile(vendorId: number): Promise<AdminVendorProfile> {
    const { data } = await client.get<AdminVendorProfile>(
      `/admin/vendors/${vendorId}/profile`,
    );
    return data;
  },

  async getComplianceScore(
    vendorId: number,
  ): Promise<AdminVendorComplianceScore> {
    const { data } = await client.get<AdminVendorComplianceScore>(
      `/admin/vendors/${vendorId}/compliance-score`,
    );
    return data;
  },

  async getInspectionHistory(
    vendorId: number,
    filters: AdminVendorInspectionFilters,
  ): Promise<AdminVendorPageResponse<AdminVendorInspection>> {
    const { data } = await client.get<
      AdminVendorPageResponse<AdminVendorInspection>
    >(`/admin/vendors/${vendorId}/inspections`, { params: filters });
    return data;
  },

  async getRegistrationStatusCounts(): Promise<VendorRegistrationStatusCounts> {
    const { data } = await client.get<VendorRegistrationStatusCounts>(
      "/admin/vendors/registration-status-counts",
    );
    return data;
  },

  async getRegistrationRequests(
    filters: VendorRegistrationFilters,
  ): Promise<AdminVendorPageResponse<VendorRegistrationSummary>> {
    const { data } = await client.get<
      AdminVendorPageResponse<VendorRegistrationSummary>
    >("/admin/vendors/registration-requests", { params: filters });
    return data;
  },

  async getRegistrationDetails(
    registrationId: number,
  ): Promise<VendorRegistrationDetails> {
    const { data } = await client.get<VendorRegistrationDetails>(
      `/admin/vendors/registration-requests/${registrationId}`,
    );
    return data;
  },

  async getRegistrationDocuments(
    registrationId: number,
  ): Promise<VendorRegistrationDocument[]> {
    const { data } = await client.get<VendorRegistrationDocument[]>(
      `/admin/vendors/registration-requests/${registrationId}/documents`,
    );
    return data;
  },

  async registerVendor(
    request: AdminRegisterVendorRequest,
  ): Promise<RegistrationApproval> {
    const { data } = await client.post<RegistrationApproval>(
      "/admin/vendors/register",
      request,
    );
    return data;
  },

  async approveRegistration(
    request: RegistrationApprovalRequest,
  ): Promise<RegistrationApprovalResponse> {
    const { data } = await client.post<RegistrationApprovalResponse>(
      "/vendor/approve-registry",
      request,
    );
    return data;
  },

  async declineRegistration(
    request: RegistrationDeclineRequest,
  ): Promise<RegistrationDeclinedResponse> {
    const { data } = await client.post<RegistrationDeclinedResponse>(
      "/vendor/decline-registry",
      request,
    );
    return data;
  },

  async requestMoreInformation(
    request: RegistrationDeclineRequest,
  ): Promise<RegistrationDeclinedResponse> {
    const { data } = await client.post<RegistrationDeclinedResponse>(
      "/vendor/request-more-information",
      request,
    );
    return data;
  },
};
