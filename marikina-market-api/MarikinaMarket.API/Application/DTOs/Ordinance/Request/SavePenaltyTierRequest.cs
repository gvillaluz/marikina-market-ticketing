using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Application.DTOs.Ordinance.Request
{
    public class SavePenaltyTierRequest
    {
        public required int OffenseNumber { get; set; }
        public required FineKind FineKind { get; set; }
        public decimal? PenaltyAmount { get; set; }
        public decimal? MaximumFine { get; set; }
        public string? PenaltyTerms { get; set; }
        public bool AllowBloodDonation { get; set; }
        public bool AllowCommunityService { get; set; }
    }
}
