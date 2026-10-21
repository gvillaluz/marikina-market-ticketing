class VendorCompliance {
  final int score;
  final String standing;
  final String frequencyLevel;
  final int? daysSinceLastTicket;
  final String severityLevel;
  final double paymentHistory;

  const VendorCompliance({
    required this.score,
    required this.standing,
    required this.frequencyLevel,
    required this.daysSinceLastTicket,
    required this.severityLevel,
    required this.paymentHistory,
  });
}
