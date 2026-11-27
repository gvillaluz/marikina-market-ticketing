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
        public AdditionalPenalty AdditionalPenalty { get; set; }
        public int? SeverityLevel => SeverityLevelOf(FineKind, PenaltyAmount, MaximumFine, AdditionalPenalty);

        // ADR 0001: the rank of the penalty the Market Code prescribes; an "up to" fine ranks by its maximum.
        public static int? SeverityLevelOf(FineKind fineKind, decimal? penaltyAmount, decimal? maximumFine, AdditionalPenalty additionalPenalty) => additionalPenalty switch
        {
            AdditionalPenalty.Imprisonment => 5,
            AdditionalPenalty.ClosureRevocation => 4,
            AdditionalPenalty.ConfiscationSuspensionImpounding => 3,
            _ => (fineKind == FineKind.Fixed ? penaltyAmount : fineKind == FineKind.UpTo ? maximumFine : null) switch
            {
                null => null,
                > 1000m => 2,
                _ => 1
            }
        };
    }
}
