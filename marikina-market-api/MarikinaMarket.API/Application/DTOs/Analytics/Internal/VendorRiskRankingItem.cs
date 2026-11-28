namespace MarikinaMarket.API.Application.DTOs.Analytics.Internal
{
    public class VendorRiskRankingItem
    {
        public required string BusinessAccountNumber { get; set; }
        public required string BusinessName { get; set; }
        public int OffenseCount { get; set; }
        public int? HighestSeverityLevel { get; set; }
        public int ComplianceScore { get; set; }
    }
}
