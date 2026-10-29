using System.ComponentModel.DataAnnotations;
using MarikinaMarket.API.Application.DTOs.Person.Request;
using MarikinaMarket.API.Application.DTOs.Person.Response;
using MarikinaMarket.API.Application.Interfaces.Services;
using MarikinaMarket.API.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MarikinaMarket.API.Presentation.Controllers;

[ApiController]
[Route("api/admin/persons")]
[Authorize(Roles = $"{nameof(Role.HeadAdmin)},{nameof(Role.AdminOfficer)}")]
public class AdminPersonController(IPersonService service) : ControllerBase
{
    [HttpPost]
    public async Task<ActionResult<PersonRecordResponse>> Create([FromBody] SavePersonRequest request)
    {
        var result = await service.SaveAsync(null, request);
        return CreatedAtAction(nameof(PersonController.Get), "Person", new { id = result.Id }, result);
    }

    [HttpPut("{id:int}")]
    public async Task<ActionResult<PersonRecordResponse>> Update([Range(1, int.MaxValue)] int id, [FromBody] SavePersonRequest request)
        => Ok(await service.SaveAsync(id, request));
}
