using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Application.DTOs.Audits.Response
{
    public class TicketHistoryEntryResponse
    {
        public required string Action { get; set; }
        public string? Details { get; set; }
        public required string PerformedBy { get; set; }
        public Role? Role { get; set; }
        public DateTime OccurredAt { get; set; }
    }
}
