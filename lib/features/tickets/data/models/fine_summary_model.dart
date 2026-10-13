import 'package:marikina_market_mobile/core/shared/domain/enums/severity.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/fine_breakdown_item_model.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/fine_summary.dart';

class FineSummaryModel {
  final double totalPaymentAmount;
  final Severity highestSeverity;
  final List<FineBreakdownItemModel> breakdownItems;

  FineSummaryModel({
    required this.totalPaymentAmount,
    required this.highestSeverity,
    required this.breakdownItems,
  });

  factory FineSummaryModel.fromJson(Map<String, dynamic> json) {
    return FineSummaryModel(
      totalPaymentAmount: (json['total_payment_amount'] as num).toDouble(),
      highestSeverity: Severity.fromValue(json['highest_severity']),
      breakdownItems: (json['breakdown'] as List)
          .map((item) => FineBreakdownItemModel.fromJson(item))
          .toList(),
    );
  }

  FineSummary toEntity() {
    return FineSummary(
      totalPaymentAmount: totalPaymentAmount,
      severity: highestSeverity,
      breakdownItems: breakdownItems.map((item) => item.toEntity()).toList(),
    );
  }
}