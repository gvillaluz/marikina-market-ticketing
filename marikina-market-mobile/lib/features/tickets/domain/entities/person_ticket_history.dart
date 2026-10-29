class PersonTicketHistory {
  final int ticketId;
  final String reference, businessName, enforcerName;
  final String? paperViolatorName, status, penaltyType;
  final DateTime issuedAt;
  final double? assessedCashFine;
  final double outstandingCashFine;
  final List<String> ordinances;
  const PersonTicketHistory({
    required this.ticketId,
    required this.reference,
    required this.businessName,
    required this.enforcerName,
    this.paperViolatorName,
    this.status,
    this.penaltyType,
    required this.issuedAt,
    this.assessedCashFine,
    required this.outstandingCashFine,
    required this.ordinances,
  });
}
