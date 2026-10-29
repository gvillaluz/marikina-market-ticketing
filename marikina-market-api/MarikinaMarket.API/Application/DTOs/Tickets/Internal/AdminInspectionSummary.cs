using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Application.DTOs.Tickets.Internal
{
    public class AdminInspectionSummary
    {
        public string? PaperReference { get; set; }
        public string? IssuePlace { get; set; }
        public int Id { get; set; }
        public int EnforcerId { get; set; }
        public required string EnforcerFirstName { get; set; }
        public required string EnforcerLastName { get; set; }
        public int VendorId { get; set; }
        public int? PersonId { get; set; }
        public string? PersonFullName { get; set; }
        public string? PaperViolatorName { get; set; }
        public string? RegisteredOwnerName { get; set; }
        public required string VendorFirstName { get; set; }
        public required string VendorLastName { get; set; }
        public required string StallNumber { get; set; }
        public required string BusinessName { get; set; }
        public int MarketSectionId { get; set; }
        public required string MarketSectionName { get; set; }
        public ViolationType Type { get; set; }
        public DateTime IssuedAt { get; set; }
    }
}