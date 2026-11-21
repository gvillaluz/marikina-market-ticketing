using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Application.DTOs.Tickets.Response
{
    public class ChangePenaltyResponse
    {
        public int TicketId { get; set; }
        public PenaltyType PenaltyType { get; set; }
        public int? CommunityServiceHours { get; set; }
        public decimal? TotalFineAmount { get; set; }
        public DateTime UpdatedAt { get; set; }
        public uint Version { get; set; }
    }
}
