using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Domain.Entities
{
    public class OrdinancePenaltyTier
    {
        public int Id { get; set; }
        public int OrdinanceId { get; set; }
        public Ordinance? Ordinance { get; set; }
        public int OffenseNumber { get; set; }
        public FineKind FineKind { get; set; }
        public decimal? PenaltyAmount { get; set; }
        public decimal? MaximumFine { get; set; }
        public string? PenaltyTerms { get; set; }
        public bool AllowBloodDonation { get; set; }
        public bool AllowCommunityService { get; set; }
    }
}
