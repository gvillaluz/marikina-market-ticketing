using System.ComponentModel.DataAnnotations;

namespace MarikinaMarket.API.Application.DTOs.Person.Request;

public class PersonMatchRequest
{
    [Required, StringLength(200)] public required string Name { get; set; }
    [StringLength(500)] public string? Address { get; set; }
    [StringLength(11)] public string? PhoneNumber { get; set; }
    [Range(0, int.MaxValue)] public int Offset { get; set; }
}
