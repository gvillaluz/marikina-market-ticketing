import 'package:marikina_market_mobile/features/tickets/domain/entities/violation_summary.dart';

class ViolationSummaryModel {
  final int ordinanceId;
  final String ordinanceNo;
  final String ordinanceCode;
  final double? paymentAmount;
  final int offenseNumber;

  ViolationSummaryModel({
    required this.ordinanceId, 
    required this.ordinanceNo, 
    required this.ordinanceCode, 
    this.paymentAmount, 
    required this.offenseNumber
  });

  factory ViolationSummaryModel.fromJson(Map<String, dynamic> json) {
    return ViolationSummaryModel(
      ordinanceId: json['ordinance_id'] as int, 
      ordinanceNo: json['ordinance_no'] as String, 
      ordinanceCode: json['ordinance_code'] as String, 
      offenseNumber: json['offense_count'] as int,
      paymentAmount: json['penalty_amount'] != null
        ? json['penalty_amount'] as double
        : null
    );
  }

  ViolationSummary toEntity() {
    return ViolationSummary(
      ordinanceId: ordinanceId, 
      ordinanceNo: ordinanceNo, 
      ordinanceCode: ordinanceCode, 
      offenseNumber: offenseNumber,
      paymentAmount: paymentAmount
    );
  }
}