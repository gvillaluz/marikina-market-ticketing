namespace MarikinaMarket.API.Domain.Enums
{
    // Why a ticket's penalty was changed. Saved only in the ticket's history text, not in the database.
    public enum PenaltyChangeReason
    {
        CannotPayCashFine,
        RequestedDifferentPenalty,
        WrongPenaltyAtIssue
    }
}
