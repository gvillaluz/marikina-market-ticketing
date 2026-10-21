import 'package:marikina_market_mobile/core/shared/domain/enums/severity.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/fine_breakdown_item.dart';

class FineSummary {
  final double totalPaymentAmount;
  final Severity severity;
  final List<FineBreakdownItem> breakdownItems;

  FineSummary({required this.totalPaymentAmount, required this.severity, required this.breakdownItems});
}