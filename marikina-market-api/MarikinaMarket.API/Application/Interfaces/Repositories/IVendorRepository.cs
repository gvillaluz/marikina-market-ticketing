using MarikinaMarket.API.Application.DTOs.Vendor.Internal;
using MarikinaMarket.API.Application.DTOs.Vendor.Request;
using MarikinaMarket.API.Domain.Entities;

namespace MarikinaMarket.API.Application.Interfaces.Repositories
{
    public interface IVendorRepository
    {
        Task<List<Business>> GetBusinessesAsync(int offset, int pageSize, AdminVendorSummaryFilter filters);
        Task<bool> BusinessAccountNumberExistsAsync(string accountNumber, int? excludingId);
        Task SaveBusinessChangesAsync();
        public Task<Business?> GetVendorProfileByUserIdAsync(int userId);
        public Task<VendorTicketSummary?> GetByIdAsync(int id);
        public Task<int?> GetVendorIdByUserIdAsync(int userId);
        public Task<int?> GetVendorUserIdAsync(int vendorId);
        public Task<Business> CreateVendorAsync(Business vendorProfile);
        public Task<VendorRegistrationRequest> AddVendorRegistryAsync(VendorRegistrationRequest vendor);
        public Task<VendorRegistrationRequest?> GetRegistrationById(int registrationId);
        public Task<bool> RegistrationEmailExistsAsync(string email);
        public Task<bool> RegistrationBusinessAccountNumberExistsAsync(string businessAccountNumber);
        public Task<VendorRegistrationStatusCounts> GetVendorRegistrationStatusCountsAsync();
        public Task<DashboardVendorCounts> GetDashboardVendorCountsAsync();
        public Task<List<VendorRegistrationSummary>> GetVendorRegistrationSummariesAsync(
            int offset,
            int pageSize,
            VendorRegistrationRequestFilters filters);
        public Task<int> GetVendorRegistrationSummaryCountAsync(VendorRegistrationRequestFilters filters);
        public Task<List<VendorLookupResult>> GetVendorByBusinessAccountNumber(string businessAccountNumber);
        public Task<VendorLookupResult?> GetVendorByQrCode(string codeValue);
        public Task<VendorProfileDetails?> GetVendorProfileDetailsAsync(int vendorId);
        public Task<List<Business>> GetVendorProfilesForComplianceUpdateAsync();
        public Task<Business?> GetVendorProfileForUpdateAsync(int vendorId);
        public Task<List<AdminVendorSummary>> GetAdminVendorSummariesAsync(
            int offset,
            int pageSize,
            AdminVendorSummaryFilter filters);
        public Task<int> GetAdminVendorSummaryCountAsync(AdminVendorSummaryFilter filters);
        public Task<int> GetVendorWarningCountThisWeekAsync(DateTime weekStart);
        public Task<int> GetVendorTicketCountThisWeekAsync(DateTime weekStart);
        public Task<List<AdminVendorActivity>> GetRecentVendorActivitiesAsync(int limit);
        public Task<List<AdminPendingTicketSettlement>> GetPendingTicketSettlementsAsync(int offset, int pageSize);
        public Task<int> GetPendingTicketSettlementCountAsync();
        public void SetOriginalVersion(VendorRegistrationRequest request, uint version);
        public Task SaveChangesAsync();
    }
}
