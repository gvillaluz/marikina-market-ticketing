enum PenaltyChangeReason {
  cannotPayCashFine('CannotPayCashFine', "Violator can't pay the cash fine"),
  requestedDifferentPenalty(
    'RequestedDifferentPenalty',
    'Violator asked for a different penalty',
  ),
  wrongPenaltyAtIssue(
    'WrongPenaltyAtIssue',
    'Wrong penalty chosen when issuing',
  );

  final String value;
  final String label;
  const PenaltyChangeReason(this.value, this.label);
}
