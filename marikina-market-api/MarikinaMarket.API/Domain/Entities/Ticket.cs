using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Domain.Entities
{
    public class Ticket
    {
        public int Id { get; set; }
        public string? ControlNumber { get; set; }

        public int VendorId { get; set; }
        public Business? Vendor {  get; set; }
        public int? PersonId { get; set; }
        public Person? Person { get; set; }
        public string? PaperViolatorName { get; set; }
        public string? PaperReference { get; set; }
        public string? SnapshotBusinessAccountNumber { get; set; }
        public string? SnapshotBusinessName { get; set; }
        public string? SnapshotRegisteredOwnerName { get; set; }
        public string? SnapshotBusinessType { get; set; }
        public string? SnapshotStallNumber { get; set; }
        public string? SnapshotMarketSectionName { get; set; }
        public string? SnapshotBusinessAddress { get; set; }

        public string? IssuePlace { get; set; }

        public int MarketSectionId { get; set; }
        public MarketSection? MarketSection { get; set; }

        public int EnforcerId { get; set; }
        public User? Enforcer { get; set; }

        public ViolationType Type { get; set; }
        public TicketStatus? Status { get; set; }
        public required string Description { get; set; }
        public decimal? TotalPaymentAmount { get; set; }
        public Severity? HighestSeverity { get; set; }
        public PenaltyType? PenaltyType { get; set; }
        public int? CommunityServiceHours { get; set; }
        public Guid? ReceiptSubmissionId { get; set; }
        public string? ReceiptSubmissionHash { get; set; }
        public List<string>? ProofUrls { get; set; }
        public List<ViolationCategory> Categories { get; set; } = [];
        public DateTime IssuedAt { get; set; }
        public DateTime? ResolvedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public uint Version { get; set; }

        public ICollection<TicketViolation> TicketViolations { get; set; } = [];
        public ICollection<TicketEvidence>? TicketEvidences { get; set; } = [];
        public ICollection<CommunityServiceLog> CommunityServiceLogs { get; set; } = [];
    }
}
