using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Application.DTOs.Recommendations.Response
{
    // One warning or ticket in which the latest run detected at least one violation category.
    public class DetectedViolationResponse
    {
        public int TicketId { get; set; }
        public string? ControlNumber { get; set; }
        public ViolationType Type { get; set; }
        public required string MarketSectionName { get; set; }
        public required string Description { get; set; }
        public DateTime IssuedAt { get; set; }
        public List<string> CategoryCodes { get; set; } = [];
    }
}
