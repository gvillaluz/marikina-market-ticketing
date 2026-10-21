import 'package:marikina_market_mobile/core/shared/domain/enums/severity.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/fine_breakdown_item.dart';

class FineBreakdownItemModel {
  final int ordinanceId;
  final String ordinanceNo;
  final String ordinanceCode;
  final double paymentAmount;
  final Severity severity;
  final int offenseNumber;
  final bool isDuplicate;

  FineBreakdownItemModel({
    required this.ordinanceId,
    required this.ordinanceNo,
    required this.ordinanceCode,
    required this.paymentAmount,
    required this.severity,
    required this.offenseNumber,
    required this.isDuplicate
  });

  factory FineBreakdownItemModel.fromJson(Map<String, dynamic> json) {
    return FineBreakdownItemModel(
      ordinanceId: json['ordinance_id'] as int,
      ordinanceNo: json['ordinance_no'] as String,
      ordinanceCode: json['ordinance_code'] as String,
      paymentAmount: (json['payment_amount'] as num).toDouble(),
      severity: Severity.fromValue(json['severity'] as String),
      offenseNumber: json['offense_number'] as int,
      isDuplicate: json['is_duplicate'] as bool
    );
  }

  FineBreakdownItem toEntity() {
    return FineBreakdownItem(
      ordinanceId: ordinanceId,
      ordinanceNo: ordinanceNo,
      ordinanceCode: ordinanceCode,
      paymentAmount: paymentAmount,
      severity: severity,
      offenseNumber: offenseNumber,
      isDuplicate: isDuplicate
    );
  }
}