namespace MarikinaMarket.API.Domain.Entities
{
    // A category the model found in one warning or ticket description during a run.
    public class RecommendationFinding
    {
        public int RecommendationRunId { get; set; }
        public RecommendationRun? RecommendationRun { get; set; }
        public int TicketId { get; set; }
        public Ticket? Ticket { get; set; }
        public required string CategoryCode { get; set; }
    }
}
