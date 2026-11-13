using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Application.DTOs.Tickets.Response
{
    public class AdminTicketDetailResponse : TicketDetailResponse
    {
        public DateTime UpdatedAt { get; set; }
        public List<string> TicketReceipts { get; set; } = [];
        public List<string> ProofUrls { get; set; } = [];
        public int? CommunityServiceHours { get; set; }
        public List<CommunityServiceLogResponse> CommunityServiceLogs { get; set; } = [];
        public decimal HoursCompleted { get; set; }
        public required uint Version { get; set; }
    }
}
