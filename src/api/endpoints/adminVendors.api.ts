import client from "@/api/client";
import { ApiRequestError } from "@/utils/apiErrors";
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

function validateRegistrationVersion(version: unknown) {
  if (
    typeof version !== "number" ||
    !Number.isSafeInteger(version) ||
    version < 1
  ) {
    throw new ApiRequestError(
      "The registration version is missing or invalid. Please reload the latest registration details.",
    );
  }
}

function validateRegistrationAction(request: RegistrationApprovalRequest) {
  if (
    !Number.isSafeInteger(request.vendorRegistrationId) ||
    request.vendorRegistrationId < 1
  ) {
    throw new ApiRequestError("The registration ID is invalid.");
  }
  validateRegistrationVersion(request.version);
}

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

  async getRegistrationStatusCounts(
    signal?: AbortSignal,
  ): Promise<VendorRegistrationStatusCounts> {
    const { data } = await client.get<VendorRegistrationStatusCounts>(
      "/admin/vendors/registration-status-counts",
      { signal },
    );
    if (
      !data ||
      ![
        data.pendingReview,
        data.needsInformation,
        data.approved,
        data.rejected,
      ].every((count) => Number.isSafeInteger(count) && count >= 0)
    ) {
      throw new ApiRequestError(
        "The server returned invalid registration counts. Please try again.",
      );
    }
    return data;
  },

  async getRegistrationRequests(
    filters: VendorRegistrationFilters,
  ): Promise<AdminVendorPageResponse<VendorRegistrationSummary>> {
    const { data } = await client.get<
      AdminVendorPageResponse<VendorRegistrationSummary>
    >("/admin/vendors/registration-requests", { params: filters });
    if (!data || !Array.isArray(data.items)) {
      throw new ApiRequestError(
        "Unable to load vendor registration requests. Please try again.",
      );
    }
    for (const item of data.items) validateRegistrationVersion(item?.version);
    return data;
  },

  async getRegistrationDetails(
    registrationId: number,
  ): Promise<VendorRegistrationDetails> {
    const { data } = await client.get<VendorRegistrationDetails>(
      `/admin/vendors/registration-requests/${registrationId}`,
    );
    validateRegistrationVersion(data?.version);
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
    validateRegistrationAction(request);
    const { data } = await client.post<RegistrationApprovalResponse>(
      "/vendor/approve-registry",
      request,
    );
    return data;
  },

  async declineRegistration(
    request: RegistrationDeclineRequest,
  ): Promise<RegistrationDeclinedResponse> {
    validateRegistrationAction(request);
    const { data } = await client.post<RegistrationDeclinedResponse>(
      "/vendor/decline-registry",
      request,
    );
    return data;
  },

  async requestMoreInformation(
    request: RegistrationDeclineRequest,
  ): Promise<RegistrationDeclinedResponse> {
    validateRegistrationAction(request);
    const { data } = await client.post<RegistrationDeclinedResponse>(
      "/vendor/request-more-information",
      request,
    );
    return data;
  },
};
