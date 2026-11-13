using System.Security.Claims;
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

        [HttpPost("{id}/review")]
        public async Task<ActionResult<RecommendationReviewResponse>> MarkReviewed([FromRoute] int id)
        {
            if (!int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var adminId) || adminId <= 0)
                return Forbid();
            return Ok(await _service.MarkReviewedAsync(id, adminId));
        }

        [HttpPost("{id}/dismiss")]
        public async Task<ActionResult<RecommendationReviewResponse>> Dismiss([FromRoute] int id)
        {
            if (!int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var adminId) || adminId <= 0)
                return Forbid();
            return Ok(await _service.DismissAsync(id, adminId));
        }
    }
}
