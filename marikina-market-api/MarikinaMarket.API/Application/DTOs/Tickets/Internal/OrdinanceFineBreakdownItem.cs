using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Application.DTOs.Tickets.Internal
{
    public class OrdinanceFineBreakdownItem
    {
        public int OrdinanceId { get; set; }
        public required string OrdinanceNo { get; set; }
        public string? Section { get; set; }
        public string? SpecificCategory { get; set; }
        public decimal? PaymentAmount { get; set; }
        public Severity? Severity { get; set; }
        public FineKind FineKind { get; set; }
        public decimal? MinimumFine { get; set; }
        public decimal? MaximumFine { get; set; }
        public string? PenaltyTerms { get; set; }
        public bool AllowBloodDonation { get; set; }
        public bool AllowCommunityService { get; set; }
        public int OffenseNumber { get; set; }
        public ViolationCategory Category { get; set; }
        public bool? IsDuplicate { get; set; }
    }
}
