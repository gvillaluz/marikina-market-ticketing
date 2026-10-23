using MarikinaMarket.API.Application.DTOs.Analytics.Response;
using MarikinaMarket.API.Application.Interfaces.Services;
using MarikinaMarket.API.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MarikinaMarket.API.Presentation.Controllers
{
    [ApiController]
    [Route("api/admin/analytics")]
    [Authorize(Roles = $"{nameof(Role.HeadAdmin)},{nameof(Role.AdminOfficer)}")]
    public class AdminAnalyticsController : ControllerBase
    {
        private readonly IAdminAnalyticsService _service;

        public AdminAnalyticsController(IAdminAnalyticsService service)
        {
            _service = service;
        }

        [HttpGet("violation-trend")]
        public async Task<ActionResult<List<ViolationTrendPointResponse>>> GetViolationTrend([FromQuery] int? year = null)
            => Ok(await _service.GetViolationTrendAsync(year));

        [HttpGet("peak-violation-times")]
        public async Task<ActionResult<List<PeakViolationTimeResponse>>> GetPeakViolationTimes([FromQuery] int? year = null)
            => Ok(await _service.GetPeakViolationTimesAsync(year));

        [HttpGet("violation-type-distribution")]
        public async Task<ActionResult<List<ViolationCategoryDistributionResponse>>> GetViolationTypeDistribution([FromQuery] int? year = null)
            => Ok(await _service.GetViolationCategoryDistributionAsync(year));

        [HttpGet("inspection-ratio")]
        public async Task<ActionResult<InspectionRatioResponse>> GetInspectionRatio([FromQuery] int? year = null)
            => Ok(await _service.GetInspectionRatioAsync(year));

        [HttpGet("resolution-rate")]
        public async Task<ActionResult<ViolationResolutionRateResponse>> GetResolutionRate([FromQuery] int? year = null)
            => Ok(await _service.GetViolationResolutionRateAsync(year));

        [HttpGet("market-section-aggregation")]
        public async Task<ActionResult<List<MarketSectionAggregationResponse>>> GetMarketSectionAggregation([FromQuery] int? year = null)
            => Ok(await _service.GetMarketSectionAggregationAsync(year));

        [HttpGet("hotspot-ranking")]
        public async Task<ActionResult<List<HotspotRankingResponse>>> GetHotspotRanking([FromQuery] int? year = null)
            => Ok(await _service.GetHotspotRankingAsync(year));

        [HttpGet("vendor-risk-ranking")]
        public async Task<ActionResult<List<VendorRiskRankingResponse>>> GetVendorRiskRanking([FromQuery] int? year = null)
            => Ok(await _service.GetVendorRiskRankingAsync(year));
    }
}
