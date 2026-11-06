class PersonTicketTotals {
  final int offenseCount, warningCount;
  final double outstandingFine;
  final DateTime? lastTicketAt;
  final String? lastBusinessName;
  final List<String> businessNames;
  const PersonTicketTotals({
    this.offenseCount = 0,
    this.warningCount = 0,
    this.outstandingFine = 0,
    this.lastTicketAt,
    this.lastBusinessName,
    this.businessNames = const [],
  });
}
