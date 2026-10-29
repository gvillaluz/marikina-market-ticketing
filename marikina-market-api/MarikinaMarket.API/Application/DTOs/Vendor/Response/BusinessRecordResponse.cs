using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Application.DTOs.Vendor.Response;

public class BusinessRecordResponse
{
    public int Id { get; set; }
    public required string BusinessAccountNumber { get; set; }
    public required string BusinessName { get; set; }
    public required string OwnerFirstName { get; set; }
    public required string OwnerLastName { get; set; }
    public required string HouseNumber { get; set; }
    public required string Street { get; set; }
    public required string Barangay { get; set; }
    public required string City { get; set; }
    public string? PhoneNumber { get; set; }
    public string? Email { get; set; }
    public int MarketSectionId { get; set; }
    public string? MarketSectionName { get; set; }
    public BusinessType BusinessType { get; set; }
    public string? StallNumber { get; set; }
    public DateTime CreatedAt { get; set; }
    public VendorStatus Status { get; set; }

    public static BusinessRecordResponse FromEntity(Business business) => new()
    {
        Id = business.Id, BusinessAccountNumber = business.BusinessAccountNumber,
        BusinessName = business.BusinessName, OwnerFirstName = business.OwnerFirstName,
        OwnerLastName = business.OwnerLastName, HouseNumber = business.HouseNumber,
        Street = business.Street, Barangay = business.Barangay, City = business.City,
        PhoneNumber = business.PhoneNumber, Email = business.Email,
        MarketSectionId = business.MarketSectionId, MarketSectionName = business.MarketSection?.Name,
        BusinessType = business.Type, StallNumber = business.StallNumber,
        CreatedAt = business.CreatedAt, Status = business.Status
    };
}
