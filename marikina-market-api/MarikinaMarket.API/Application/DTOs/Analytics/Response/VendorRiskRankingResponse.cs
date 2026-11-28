namespace MarikinaMarket.API.Application.DTOs.Analytics.Response
{
    public class VendorRiskRankingResponse
    {
        public int Rank { get; set; }
        public required string BusinessAccountNumber { get; set; }
        public required string BusinessName { get; set; }
        public int OffenseCount { get; set; }
        public int? HighestSeverityLevel { get; set; }
        public int RiskScore { get; set; }
    }
}
