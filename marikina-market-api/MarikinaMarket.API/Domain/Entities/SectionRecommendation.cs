namespace MarikinaMarket.API.Domain.Entities
{
    // The recommendation for one market section in a run. Times are UTC; hours are Manila hours (0 to 23).
    public class SectionRecommendation
    {
        public int Id { get; set; }
        public int RecommendationRunId { get; set; }
        public RecommendationRun? RecommendationRun { get; set; }
        public int MarketSectionId { get; set; }
        public MarketSection? MarketSection { get; set; }
        public required string CategoryCode { get; set; }
        public required string CategoryNameEnglish { get; set; }
        public required string CategoryNameFilipino { get; set; }
        public required string RecommendedAction { get; set; }
        public int CategoryRecordCount { get; set; }
        public int SectionRecordCount { get; set; }
        public decimal RiskScore { get; set; }
        public required string RiskLevel { get; set; }
        public required string PatternConfidence { get; set; }
        public int PeakStartHour { get; set; }
        public List<int> HourlyCounts { get; set; } = [];
        public DateTime LastFlaggedAt { get; set; }
    }
}
