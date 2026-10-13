import 'package:marikina_market_mobile/core/shared/domain/enums/severity.dart';

class FineBreakdownItem {
  final int ordinanceId;
  final String ordinanceNo;
  final String ordinanceCode;
  final double paymentAmount;
  final Severity severity;
  final int offenseNumber;
  final bool isDuplicate;

  FineBreakdownItem({required this.ordinanceId, required this.ordinanceNo, required this.ordinanceCode, required this.paymentAmount, required this.severity, required this.offenseNumber, required this.isDuplicate});
}