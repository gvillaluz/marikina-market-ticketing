using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Application.DTOs.Vendor.Internal
{
    public class VendorRegistrationSummary
    {
        public int RegistrationId { get; set; }
        public uint Version { get; set; }
        public required string BusinessAccountNumber { get; set; }
        public required string BusinessName { get; set; }
        public required string VendorName { get; set; }
        public BusinessType BusinessType { get; set; }
        public required string MarketSectionName { get; set; }
        public string? StallNumber { get; set; }
        public DateTime RequestedAt { get; set; }
        public RequestStatus Status { get; set; }
    }
}
