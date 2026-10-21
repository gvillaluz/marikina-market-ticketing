class ViolationSummary {
  final int ordinanceId;
  final String ordinanceNo;
  final String ordinanceCode;
  final double? paymentAmount;
  final int offenseNumber;

  ViolationSummary({required this.ordinanceId, required this.ordinanceNo, required this.ordinanceCode, this.paymentAmount, required this.offenseNumber});
}