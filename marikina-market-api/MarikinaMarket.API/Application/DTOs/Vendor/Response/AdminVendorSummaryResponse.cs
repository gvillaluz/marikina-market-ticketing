using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Application.DTOs.Vendor.Response
{
    public class AdminVendorSummaryResponse
    {
        public int VendorId { get; set; }
        public required string BusinessAccountNumber { get; set; }
        public required string VendorName { get; set; }
        public string BusinessName { get; set; } = "";
        public BusinessType Type { get; set; }
        public required string MarketSectionName { get; set; }
        public int ComplianceScore { get; set; }
        public int WarningCount { get; set; }
        public int TicketCount { get; set; }
    }
}
