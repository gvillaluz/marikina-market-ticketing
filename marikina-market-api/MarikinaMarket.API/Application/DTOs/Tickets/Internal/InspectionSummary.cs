using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Application.DTOs.Tickets.Internal
{
    public class InspectionSummary
    {
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
        public BusinessType BusinessType { get; init; }
        public required string BusinessAccountNumber { get; init; }
        public string? StallNumber { get; init; }
        public required int EnforcerId { get; init; }
        public required ViolationType Type { get; init; }
        public TicketStatus? Status { get; init; }
        public Severity? Severity { get; init; }
        public required List<string> Ordinances { get; init; } = [];
        public required DateTime IssuedAt { get; init; }
        public DateTime UpdatedAt { get; init; }
    }
}
