using System.ComponentModel.DataAnnotations;
using MarikinaMarket.API.Application.DTOs.Tickets.Response;
using MarikinaMarket.API.Application.DTOs.Vendor.Request;
using MarikinaMarket.API.Application.DTOs.Vendor.Response;
using MarikinaMarket.API.Application.Interfaces.Services;
using MarikinaMarket.API.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MarikinaMarket.API.Presentation.Controllers;

[ApiController]
[Route("api/admin/businesses")]
[Authorize(Roles = $"{nameof(Role.HeadAdmin)},{nameof(Role.AdminOfficer)}")]
public class AdminBusinessController : ControllerBase
{
    private readonly IVendorService _service;
    public AdminBusinessController(IVendorService service) => _service = service;

    [HttpGet]
    public async Task<ActionResult<PageResponse<BusinessRecordResponse>>> List(
        [FromQuery] AdminVendorSummaryFilter filters, [FromQuery, Range(0, int.MaxValue)] int offset = 0)
        => Ok(await _service.GetBusinessesAsync(offset, filters));

    [HttpGet("{id:int}")]
    public async Task<ActionResult<BusinessRecordResponse>> Get([Range(1, int.MaxValue)] int id)
        => Ok(await _service.GetBusinessAsync(id));

    [HttpPost]
    public async Task<ActionResult<BusinessRecordResponse>> Create([FromBody] SaveBusinessRequest request)
    {
        var result = await _service.SaveBusinessAsync(null, request);
        return CreatedAtAction(nameof(Get), new { id = result.Id }, result);
    }

    [HttpPut("{id:int}")]
    public async Task<ActionResult<BusinessRecordResponse>> Update(
        [Range(1, int.MaxValue)] int id, [FromBody] SaveBusinessRequest request)
        => Ok(await _service.SaveBusinessAsync(id, request));
}
