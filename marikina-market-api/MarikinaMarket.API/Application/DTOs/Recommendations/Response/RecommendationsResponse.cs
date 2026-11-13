using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Application.DTOs.Recommendations.Response
{
    public class RecommendationsResponse
    {
        public RecommendationRunResponse? Run { get; set; }
        public List<SectionRecommendationResponse> Recommendations { get; set; } = [];
        public List<string> SectionsWithoutRecommendation { get; set; } = [];
    }

    public class RecommendationRunResponse
    {
        public DateTime FinishedAt { get; set; }
        public DateTime WindowStart { get; set; }
        public DateTime WindowEnd { get; set; }
        public int RecordCount { get; set; }
    }

    public class SectionRecommendationResponse
    {
        public int Id { get; set; }
        public int MarketSectionId { get; set; }
        public required string MarketSectionName { get; set; }
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
        public RecommendationReviewResponse? Review { get; set; }
    }

    public class RecommendationReviewResponse
    {
        public RecommendationDecision Decision { get; set; }
        public required string ReviewedByName { get; set; }
        public DateTime ReviewedAt { get; set; }
    }
}
