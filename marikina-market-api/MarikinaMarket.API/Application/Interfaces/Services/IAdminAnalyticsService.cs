using MarikinaMarket.API.Application.DTOs.Analytics.Response;

namespace MarikinaMarket.API.Application.Interfaces.Services
{
    public interface IAdminAnalyticsService
    {
        Task<List<ViolationTrendPointResponse>> GetViolationTrendAsync(int? year = null);
        Task<List<PeakViolationTimeResponse>> GetPeakViolationTimesAsync(int? year = null);
        Task<List<ViolationCategoryDistributionResponse>> GetViolationCategoryDistributionAsync(int? year = null);
        Task<InspectionRatioResponse> GetInspectionRatioAsync(int? year = null);
        Task<ViolationResolutionRateResponse> GetViolationResolutionRateAsync(int? year = null);
        Task<List<MarketSectionAggregationResponse>> GetMarketSectionAggregationAsync(int? year = null);
        Task<List<HotspotRankingResponse>> GetHotspotRankingAsync(int? year = null);
        Task<List<VendorRiskRankingResponse>> GetVendorRiskRankingAsync(int? year = null);
    }
}
