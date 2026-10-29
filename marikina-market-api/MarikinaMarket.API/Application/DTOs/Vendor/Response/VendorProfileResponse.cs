using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Application.DTOs.Vendor.Response
{
    public class VendorProfileResponse
    {
        public required string Name { get; set; }
        public string BusinessAccountNumber { get; set; } = "";
        public string BusinessName { get; set; } = "";
        public string? PhoneNumber { get; set; }
        public string? Email { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? LastViolationIssuedAt { get; set; }
    }
}
