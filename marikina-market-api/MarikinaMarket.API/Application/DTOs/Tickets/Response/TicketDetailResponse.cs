using MarikinaMarket.API.Application.DTOs.Tickets.Internal;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Application.DTOs.Tickets.Response
{
    public class TicketDetailResponse
    {
        public string? PaperReference { get; set; }
        public string? IssuePlace { get; set; }
        public int TicketId { get; set; }
        public int EnforcerId { get; set; }
        public int VendorId { get; set; }
        public int? PersonId { get; set; }
        public string? PersonFullName { get; set; }
        public string? PaperViolatorName { get; set; }
        public string? RegisteredOwnerName { get; set; }
        public string? ControlNumber { get; set; }
        public ViolationType Type { get; set; }
        public BusinessType BusinessType { get; set; }
        public required string BusinessAccountNumber { get; set; }
        public string? StallNumber { get; set; }
        public required string BusinessName { get; set; }
        public required string LastName { get; set; }
        public required string FirstName { get; set; }
        public required string Address { get; set; }
        public List<TicketViolationSummary> Violations { get; set; } = [];
        public DateTime IssuedAt { get; set; }
        public required string MarketSectionName { get; set; }
        public List<ViolationCategory> Categories { get; set; } = [];
        public required string Description { get; set; }
        public Severity? Severity { get; set; }
        public PenaltyType? PenaltyType { get; set; }
        public TicketStatus? Status { get; set; }
        public DateTime? DueDate { get; set; }
        public decimal? TotalFineAmount { get; set; }
        public List<String>? TicketEvidences { get; set; } = [];
    }
}
