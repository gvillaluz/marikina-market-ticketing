using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Application.DTOs.Tickets.Response
{
    public class PenaltyOptionsResponse
    {
        public int TicketId { get; set; }
        public PenaltyType? CurrentPenaltyType { get; set; }
        public List<PenaltyType> AllowedPenaltyTypes { get; set; } = [];
        public decimal? CashFineAmount { get; set; }
        public int? CommunityServiceHours { get; set; }
        public uint Version { get; set; }
    }
}
