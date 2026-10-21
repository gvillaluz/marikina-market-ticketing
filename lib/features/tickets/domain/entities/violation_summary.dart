class ViolationSummary {
  final int ordinanceId;
  final String ordinanceNo;
  final String series;
  final String ordinanceCode;
  final double? paymentAmount;
  final int offenseNumber;

  ViolationSummary({
    required this.ordinanceId,
    required this.ordinanceNo,
    this.series = '',
    required this.ordinanceCode,
    this.paymentAmount,
    required this.offenseNumber,
  });
}
