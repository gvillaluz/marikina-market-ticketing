using System.ComponentModel.DataAnnotations;
using MarikinaMarket.API.Application.DTOs.Tickets.Request;
using MarikinaMarket.API.Application.DTOs.Tickets.Response;
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
    [Route("api/admin/vendors")]
    [Authorize(Roles = $"{nameof(Role.HeadAdmin)},{nameof(Role.AdminOfficer)}")]
    public class AdminVendorController : ControllerBase
    {
        private readonly IVendorService _service;
        private readonly ITicketService _ticketService;

        public AdminVendorController(IVendorService service, ITicketService ticketService)
        {
            _service = service;
            _ticketService = ticketService;
        }

        [HttpGet]
        public async Task<ActionResult<PageResponse<AdminVendorSummaryResponse>>> GetVendorSummaries(
            [FromQuery] AdminVendorSummaryFilter filters,
            [FromQuery, Range(0, int.MaxValue)] int offset = 0)
            => Ok(await _service.GetAdminVendorSummariesAsync(offset, filters));

        [HttpGet("compliance-overview")]
        public async Task<ActionResult<AdminVendorComplianceOverviewResponse>> GetComplianceOverview()
            => Ok(await _service.GetAdminVendorComplianceOverviewAsync());

        [HttpGet("pending-settlements")]
        public async Task<ActionResult<PageResponse<AdminPendingTicketSettlementResponse>>> GetPendingTicketSettlements(
            [FromQuery, Range(0, int.MaxValue)] int offset = 0)
            => Ok(await _service.GetPendingTicketSettlementsAsync(offset));

        [HttpGet("community-service-logs")]
        public async Task<ActionResult<PageResponse<AdminCommunityServiceLogResponse>>> GetCommunityServiceLogs(
            [FromQuery] AdminCommunityServiceLogFilters filters,
            [FromQuery, Range(0, int.MaxValue)] int offset = 0)
            => Ok(await _ticketService.GetCommunityServiceLogsAsync(offset, filters.Status));

        [HttpGet("{vendorId:int}/profile")]
        public async Task<ActionResult<VendorProfileResponse>> GetVendorProfile([FromRoute, Range(1, int.MaxValue)] int vendorId)
            => Ok(await _service.GetVendorProfileAsync(vendorId));

        [HttpGet("{vendorId:int}/compliance-score")]
        public async Task<ActionResult<VendorComplianceScoreResponse>> GetVendorComplianceScore(
            [FromRoute, Range(1, int.MaxValue)] int vendorId)
            => Ok(await _service.GetVendorComplianceScoreAsync(vendorId));

        [HttpGet("{vendorId:int}/inspections")]
        public async Task<ActionResult<PageResponse<VendorInspectionHistoryResponse>>> GetVendorInspectionHistory(
            [FromRoute, Range(1, int.MaxValue)] int vendorId,
            [FromQuery] VendorInspectionHistoryFilters filters,
            [FromQuery, Range(0, int.MaxValue)] int offset = 0)
            => Ok(await _ticketService.GetVendorInspectionHistoryAsync(vendorId, offset, filters));
    }
}
