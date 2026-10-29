using System.ComponentModel.DataAnnotations;

namespace MarikinaMarket.API.Application.DTOs.Person.Request;

public class PersonSearchRequest
{
    [StringLength(500)] public string? Search { get; set; }
}
