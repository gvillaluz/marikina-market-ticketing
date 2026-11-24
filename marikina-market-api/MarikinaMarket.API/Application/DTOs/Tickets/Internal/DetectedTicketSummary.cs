using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Application.DTOs.Tickets.Internal
{
    public class DetectedTicketSummary
    {
        public required int Id { get; init; }
        public string? ControlNumber { get; init; }
        public string? PaperReference { get; init; }
        public required ViolationType Type { get; init; }
        public required string MarketSectionName { get; init; }
        public required string Description { get; init; }
        public required DateTime IssuedAt { get; init; }
    }
}
