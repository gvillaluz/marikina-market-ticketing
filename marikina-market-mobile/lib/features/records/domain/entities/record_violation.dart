class RecordViolation {
  final String ordinanceNumber;
  final String ordinanceCode;
  final int offenseCount;
  final double? penaltyAmount;
  const RecordViolation({
    required this.ordinanceNumber,
    required this.ordinanceCode,
    required this.offenseCount,
    required this.penaltyAmount,
  });
}
