using MarikinaMarket.API.Application.DTOs.Tickets.Internal;
using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Application.DTOs.Tickets.Response
{
    public class InspectionSummaryResponse
    {
        public BusinessSnapshotResponse? BusinessSnapshot { get; set; }
        public string? PaperReference { get; set; }
        public string? IssuePlace { get; set; }
        public required int Id { get; init; }
        public required string ControlNumber { get; init; }
        public required int VendorId { get; init; }
        public int? PersonId { get; set; }
        public string? PersonFullName { get; set; }
        public string? PaperViolatorName { get; set; }
        public string? RegisteredOwnerName { get; set; }
        public required string LastName { get; init; }
        public required string FirstName { get; init; }
        public required string BusinessName { get; init; }
        public required int MarketSectionId { get; init; }
        public required string MarketSectionName { get; init; }
        public required string BusinessAccountNumber { get; init; }
        public BusinessType BusinessType { get; init; }
        public string? StallNumber { get; init; }
        public required int EnforcerId { get; init; }
        public required ViolationType Type { get; init; }
        public required TicketStatus? Status { get; init; }
        public Severity? Severity { get; init; }
        public required List<string> OrdinanceNames { get; init; } = [];
        public required DateTime IssuedAt { get; init; }
        public DateTime? OverdueDate { get; init; }
        public DateTime UpdatedAt { get; init; }
        public List<DuplicateOrdinance>? DuplicateOrdinances { get; init; }
        public string? WarningMessageForDuplicates { get; init; }
    }
}
