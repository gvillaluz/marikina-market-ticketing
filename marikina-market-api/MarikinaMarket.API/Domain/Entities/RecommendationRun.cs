namespace MarikinaMarket.API.Domain.Entities
{
    // One finished run of the recommendation model. Written only by the connector in description-model/connector.
    public class RecommendationRun
    {
        public int Id { get; set; }
        public DateTime StartedAt { get; set; }
        public DateTime FinishedAt { get; set; }
        public DateTime WindowStart { get; set; }
        public DateTime WindowEnd { get; set; }
        public required string ModelVersion { get; set; }
        public int RecordCount { get; set; }

        public ICollection<RecommendationFinding> Findings { get; set; } = [];
        public ICollection<SectionRecommendation> SectionRecommendations { get; set; } = [];
    }
}
