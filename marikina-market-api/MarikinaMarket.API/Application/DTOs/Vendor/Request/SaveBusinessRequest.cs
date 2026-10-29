using System.ComponentModel.DataAnnotations;
using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Application.DTOs.Vendor.Request;

public class SaveBusinessRequest
{
    [Required, StringLength(20)] public required string BusinessAccountNumber { get; set; }
    [Required, StringLength(100)] public required string BusinessName { get; set; }
    [Required, StringLength(100)] public required string OwnerFirstName { get; set; }
    [Required, StringLength(100)] public required string OwnerLastName { get; set; }
    [Required, StringLength(50)] public required string HouseNumber { get; set; }
    [Required, StringLength(50)] public required string Street { get; set; }
    [Required, StringLength(60)] public required string Barangay { get; set; }
    [Required, StringLength(100)] public required string City { get; set; }
    [RegularExpression(@"^09\d{9}$")] public string? PhoneNumber { get; set; }
    [EmailAddress, StringLength(255)] public string? Email { get; set; }
    [Range(1, int.MaxValue)] public int MarketSectionId { get; set; }
    [Required, EnumDataType(typeof(BusinessType))] public BusinessType? BusinessType { get; set; }
    [StringLength(20)] public string? StallNumber { get; set; }
}
