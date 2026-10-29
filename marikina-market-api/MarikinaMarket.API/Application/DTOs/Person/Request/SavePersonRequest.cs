using System.ComponentModel.DataAnnotations;

namespace MarikinaMarket.API.Application.DTOs.Person.Request;

public class SavePersonRequest
{
    [Required, StringLength(200)] public required string FullName { get; set; }
    [Required, StringLength(500)] public required string Address { get; set; }
    // Validation after optional whitespace normalization is performed by the service.
    public string? PhoneNumber { get; set; }
}
