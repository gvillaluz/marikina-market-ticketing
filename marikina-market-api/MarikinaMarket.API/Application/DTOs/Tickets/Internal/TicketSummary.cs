using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Application.DTOs.Tickets.Internal
{
    public class TicketSummary
    {
        public string? PaperReference { get; set; }
        public string? IssuePlace { get; set; }
        public required int Id { get; init; }
        public required string ControlNumber { get; init; }
        public required int VendorId { get; init; }
        public int? PersonId { get; set; }
        public string? PersonFullName { get; set; }
        public string? PaperViolatorName { get; set; }
        public string? RegisteredOwnerName { get; set; }
        public BusinessType BusinessType { get; set; }
        public required string BusinessName { get; init; }
        public required string MarketSectionName { get; init; }
        public required string BusinessAccountNumber { get; set; }
        public string? StallNumber { get; init; }
        public List<string> OrdinanceNames { get; init; } = [];
        public required int EnforcerId { get; init; }
        public TicketStatus? Status { get; init; }
        public required DateTime IssuedAt { get; init; }
        public DateTime UpdatedAt { get; init; }
    }
}
