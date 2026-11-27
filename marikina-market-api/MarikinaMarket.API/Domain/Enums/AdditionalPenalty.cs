namespace MarikinaMarket.API.Domain.Enums;

// The penalty the Market Code explicitly prescribes beside the fine (ADR 0001).
public enum AdditionalPenalty
{
    None = 0,
    ConfiscationSuspensionImpounding = 1,
    ClosureRevocation = 2,
    Imprisonment = 3
}
