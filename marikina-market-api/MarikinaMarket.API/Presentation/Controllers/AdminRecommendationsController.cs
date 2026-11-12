using MarikinaMarket.API.Application.DTOs.Recommendations.Response;
using MarikinaMarket.API.Application.Interfaces.Services;
using MarikinaMarket.API.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MarikinaMarket.API.Presentation.Controllers
{
    [ApiController]
    [Route("api/admin/recommendations")]
    [Authorize(Roles = $"{nameof(Role.HeadAdmin)},{nameof(Role.AdminOfficer)}")]
    public class AdminRecommendationsController : ControllerBase
    {
        private readonly IRecommendationService _service;

        public AdminRecommendationsController(IRecommendationService service) => _service = service;

        [HttpGet]
        public async Task<ActionResult<RecommendationsResponse>> GetLatest()
            => Ok(await _service.GetLatestAsync());
    }
}
