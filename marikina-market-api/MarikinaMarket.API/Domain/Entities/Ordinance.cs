using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Domain.Entities
{
    public class Ordinance
    {
        public int Id { get; set; }
        public required string OrdinanceNo { get; set; }
        public required string Series { get; set; }
        public string? Section { get; set; }
        public required string Title { get; set; }
        public ViolationCategory Category { get; set; }
        public string? SpecificCategory { get; set; }
        public Severity? Severity { get; set; }
        public bool WarningEligible { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; }
        public bool IsActive { get; set; } = true;

        public ICollection<OrdinancePenaltyTier> PenaltyTiers { get; set; } = [];
        public ICollection<TicketViolation> TicketViolations { get; set; } = [];
    }
}
