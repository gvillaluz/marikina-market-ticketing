import client from "@/api/client";
import type {
  BusinessRecord,
  SaveBusinessRequest,
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
} from "@/api/types/admin-vendor.types";

export const adminVendorsApi = {
  async getBusiness(id: number): Promise<BusinessRecord> {
    const { data } = await client.get<BusinessRecord>(`/admin/businesses/${id}`);
    return data;
  },
  async saveBusiness(id: number | null, request: SaveBusinessRequest): Promise<BusinessRecord> {
    const payload = {
      ...request,
      phoneNumber: request.phoneNumber?.trim() || null,
      email: request.email?.trim() || null,
    };
    const { data } = id === null
      ? await client.post<BusinessRecord>("/admin/businesses", payload)
      : await client.put<BusinessRecord>(`/admin/businesses/${id}`, payload);
    return data;
  },
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
};
