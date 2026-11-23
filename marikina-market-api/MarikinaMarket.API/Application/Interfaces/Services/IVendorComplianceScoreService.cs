using MarikinaMarket.API.Application.DTOs.Vendor.Internal;
using MarikinaMarket.API.Application.DTOs.Vendor.Response;

namespace MarikinaMarket.API.Application.Interfaces.Services
{
    public interface IVendorComplianceScoreService
    {
        // The caller owns the transaction so ticket and score writes commit together.
        Task<VendorComplianceScoreResponse> RefreshAsync(int vendorId, DateTime calculatedAt);
        // Updates businesses not yet updated on the current Manila day. Each save stands alone.
        Task RefreshDueAsync(DateTime calculatedAt);
        // The breakdown of the saved score, as of its last update. Saves nothing.
        Task<VendorComplianceScoreResponse> GetSavedAsync(int vendorId);
        VendorComplianceScoreResponse Calculate(
            IReadOnlyCollection<VendorComplianceTicket> tickets,
            DateTime calculatedAt);
    }
}
