import 'package:marikina_market_mobile/features/tickets/domain/entities/violation_summary.dart';

class ViolationSummaryModel {
  final int ordinanceId;
  final String ordinanceNo;
  final String series;
  final String? section;
  final String? specificCategory;
  final double? paymentAmount;
  final int offenseNumber;

  ViolationSummaryModel({
    required this.ordinanceId,
    required this.ordinanceNo,
    this.series = '',
    required this.section,
    this.specificCategory,
    this.paymentAmount,
    required this.offenseNumber,
  });

  factory ViolationSummaryModel.fromJson(Map<String, dynamic> json) {
    return ViolationSummaryModel(
      ordinanceId: json['ordinance_id'] as int,
      ordinanceNo: json['ordinance_no'] as String,
      series: json['series'] as String? ?? '',
      section: json['section'] as String?,
      specificCategory: json['specific_category'] as String?,
      offenseNumber: json['offense_count'] as int,
      paymentAmount: (json['penalty_amount'] as num?)?.toDouble(),
    );
  }

  ViolationSummary toEntity() {
    return ViolationSummary(
      ordinanceId: ordinanceId,
      ordinanceNo: ordinanceNo,
      series: series,
      section: section,
      specificCategory: specificCategory,
      offenseNumber: offenseNumber,
      paymentAmount: paymentAmount,
    );
  }
}
