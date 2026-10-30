using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Application.DTOs.Tickets.Response
{
    public class TicketSummaryResponse
    {
        public BusinessSnapshotResponse? BusinessSnapshot { get; set; }
        public string? PaperReference { get; set; }
        public string? IssuePlace { get; set; }
        public int Id { get; set; }
        public int EnforcerId { get; set; }
        public int VendorId { get; set; }
        public int? PersonId { get; set; }
        public string? PersonFullName { get; set; }
        public string? PaperViolatorName { get; set; }
        public string? RegisteredOwnerName { get; set; }
        public required string ControlNumber { get; set; }
        public TicketStatus Status { get; set; }
        public required string BusinessName { get; set; }
        public required BusinessType BusinessType { get; set; }
        public required string BusinessAccountNumber { get; set; }
        public string? StallNumber { get; set; }
        public List<string> OrdinanceNames { get; set; } = [];
        public required string MarketSectionName { get; set; }
        public DateTime IssuedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public DateTime OverdueDate { get; set; }
    }
}
