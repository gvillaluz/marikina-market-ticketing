using MarikinaMarket.API.Application.DTOs.Person.Response;
using MarikinaMarket.API.Application.DTOs.Tickets.Response;
using MarikinaMarket.API.Application.DTOs.User.Request;
using MarikinaMarket.API.Application.DTOs.Vendor.Internal;
using MarikinaMarket.API.Application.DTOs.Vendor.Request;
using MarikinaMarket.API.Application.DTOs.Vendor.Response;
using MarikinaMarket.API.Application.Interfaces.Services;
using MarikinaMarket.API.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace MarikinaMarket.API.Presentation.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class VendorController : ControllerBase
    {
        private readonly IVendorService _service;

        public VendorController(IVendorService service) => _service = service;

        [HttpGet("dashboard")]
        [Authorize(Roles = nameof(Role.MarketVendor))]
        public async Task<ActionResult<VendorDashboardResponse>> GetOwnDashboard()
        {
            if (!int.TryParse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value, out var userId) || userId <= 0)
                return Unauthorized("Invalid token.");
            return Ok(await _service.GetOwnDashboardAsync(userId));
        }

        [HttpGet("profile")]
        [Authorize(Roles = nameof(Role.MarketVendor))]
        public async Task<ActionResult<VendorSelfProfileResponse>> GetOwnProfile()
        {
            if (!int.TryParse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value, out var userId) || userId <= 0)
                return Unauthorized("Invalid token.");
            return Ok(await _service.GetOwnProfileAsync(userId));
        }

        [HttpPut("profile")]
        [Authorize(Roles = nameof(Role.MarketVendor))]
        public async Task<ActionResult<VendorSelfProfileResponse>> UpdateOwnProfile([FromBody] EditUserRequest request)
        {
            if (!int.TryParse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value, out var userId) || userId <= 0)
                return Unauthorized("Invalid token.");
            return Ok(await _service.UpdateOwnProfileAsync(userId, request));
        }

        [HttpGet("lookup")]
        [Authorize(Roles = nameof(Role.MarketEnforcer))]
        public async Task<ActionResult<PageResponse<GetVendorResponse>>> SearchBusinesses([FromQuery] string? search)
            => Ok(await _service.SearchBusinessesAsync(search));

        [HttpGet("{businessId:int}/people")]
        [Authorize(Roles = nameof(Role.MarketEnforcer))]
        public async Task<ActionResult<List<PersonSummaryResponse>>> GetBusinessPeople(
            [FromRoute] int businessId, [FromServices] ITicketService tickets)
            => Ok(await tickets.GetBusinessPeopleAsync(businessId));
    }
}
