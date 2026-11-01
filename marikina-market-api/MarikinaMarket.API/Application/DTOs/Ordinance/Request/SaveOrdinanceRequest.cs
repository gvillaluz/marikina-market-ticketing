using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Application.DTOs.Ordinance.Request
{
    public class SaveOrdinanceRequest
    {
        public required string OrdinanceNumber { get; set; }
        public required string Series { get; set; }
        public required string Section { get; set; }
        public required ViolationCategory Category { get; set; }
        public string? SpecificCategory { get; set; }
        public required string Title { get; set; }
        public required Severity? Severity { get; set; }
        public bool WarningEligible { get; set; }
        public required List<SavePenaltyTierRequest> PenaltyTiers { get; set; }
    }
}
