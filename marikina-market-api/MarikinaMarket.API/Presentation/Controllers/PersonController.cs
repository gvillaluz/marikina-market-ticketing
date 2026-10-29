using System.ComponentModel.DataAnnotations;
using MarikinaMarket.API.Application.DTOs.Person.Request;
using MarikinaMarket.API.Application.DTOs.Person.Response;
using MarikinaMarket.API.Application.DTOs.Tickets.Response;
using MarikinaMarket.API.Application.Interfaces.Services;
using MarikinaMarket.API.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MarikinaMarket.API.Presentation.Controllers;

[ApiController]
[Route("api/persons")]
[Authorize(Roles = $"{nameof(Role.HeadAdmin)},{nameof(Role.AdminOfficer)},{nameof(Role.MarketEnforcer)}")]
public class PersonController(IPersonService service) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<PageResponse<PersonRecordResponse>>> List(
        [FromQuery] PersonSearchRequest filters, [FromQuery, Range(0, int.MaxValue)] int offset = 0)
        => Ok(await service.SearchAsync(filters, offset));

    [HttpGet("{id:int}")]
    public async Task<ActionResult<PersonRecordResponse>> Get([Range(1, int.MaxValue)] int id)
        => Ok(await service.GetAsync(id));

    [HttpPost]
    [Authorize(Roles = nameof(Role.MarketEnforcer))]
    public async Task<ActionResult<PersonRecordResponse>> Create([FromBody] SavePersonRequest request)
    {
        var person = await service.SaveAsync(null, request);
        return CreatedAtAction(nameof(Get), new { id = person.Id }, person);
    }

    [HttpPost("matches")]
    public async Task<ActionResult<PageResponse<PersonCandidateResponse>>> Matches([FromBody] PersonMatchRequest request)
        => Ok(await service.MatchAsync(request));

    [HttpGet("{id:int}/tickets")]
    public async Task<ActionResult<PageResponse<PersonTicketHistoryResponse>>> History(
        [Range(1, int.MaxValue)] int id, [FromQuery, Range(0, int.MaxValue)] int offset,
        [FromServices] ITicketService tickets) => Ok(await tickets.GetPersonHistoryAsync(id, offset));
}
