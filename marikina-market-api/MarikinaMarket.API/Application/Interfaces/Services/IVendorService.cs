using MarikinaMarket.API.Application.DTOs.User.Request;
using MarikinaMarket.API.Application.DTOs.Tickets.Response;
using MarikinaMarket.API.Application.DTOs.Vendor.Internal;
using MarikinaMarket.API.Application.DTOs.Vendor.Request;
using MarikinaMarket.API.Application.DTOs.Vendor.Response;

namespace MarikinaMarket.API.Application.Interfaces.Services
{
    public interface IVendorService
    {
        Task<PageResponse<BusinessRecordResponse>> GetBusinessesAsync(int offset, AdminVendorSummaryFilter filters);
        Task<BusinessRecordResponse> GetBusinessAsync(int id);
        Task<BusinessRecordResponse> SaveBusinessAsync(int? id, SaveBusinessRequest request);
        Task<VendorDashboardResponse> GetOwnDashboardAsync(int userId);
        public Task<VendorSelfProfileResponse> GetOwnProfileAsync(int userId);
        public Task<VendorSelfProfileResponse> UpdateOwnProfileAsync(int userId, EditUserRequest request);
        public Task<PageResponse<GetVendorResponse>> SearchBusinessesAsync(string? search);
        public Task<PageResponse<AdminVendorSummaryResponse>> GetAdminVendorSummariesAsync(
            int offset,
            AdminVendorSummaryFilter filters);
        public Task<AdminVendorComplianceOverviewResponse> GetAdminVendorComplianceOverviewAsync();
        public Task<PageResponse<AdminPendingTicketSettlementResponse>> GetPendingTicketSettlementsAsync(int offset);
        public Task<VendorProfileResponse> GetVendorProfileAsync(int vendorId);
        public Task<VendorComplianceScoreResponse> GetVendorComplianceScoreAsync(int vendorId);
    }
}
