using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Application.DTOs.Enforcers.Internal
{
    // One warning or ticket, with what the one-enforcer report groups it by.
    public class EnforcerActivityRecord
    {
        public ViolationType Type { get; set; }
        public TicketStatus? Status { get; set; }
        public PenaltyType? PenaltyType { get; set; }
        public decimal? Fine { get; set; }
        public int MarketSectionId { get; set; }
        public required string MarketSectionName { get; set; }
        public List<ViolationCategory> Categories { get; set; } = [];
    }
}
