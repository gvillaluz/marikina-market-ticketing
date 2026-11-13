using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Domain.Entities
{
    // An administrator's decision on one card, made on the run in RecommendationRunId. Time is UTC.
    // It applies to later runs for as long as the same section and category keep having a card.
    public class RecommendationReview
    {
        public int Id { get; set; }
        public int MarketSectionId { get; set; }
        public required string CategoryCode { get; set; }
        public RecommendationDecision Decision { get; set; }
        public int ReviewedById { get; set; }
        public required string ReviewedByName { get; set; }
        public DateTime ReviewedAt { get; set; }
        public int RecommendationRunId { get; set; }
        public RecommendationRun? RecommendationRun { get; set; }
    }
}
