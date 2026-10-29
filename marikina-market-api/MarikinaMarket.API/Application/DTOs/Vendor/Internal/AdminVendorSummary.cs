using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Application.DTOs.Vendor.Internal
{
    public class AdminVendorSummary
    {
        public int VendorId { get; set; }
        public required string BusinessAccountNumber { get; set; }
        public required string VendorName { get; set; }
        public string BusinessName { get; set; } = "";
        public BusinessType BusinessType { get; set; }
        public required string MarketSectionName { get; set; }
        public int ComplianceScore { get; set; }
        public int WarningCount { get; set; }
        public int TicketCount { get; set; }
    }
}
