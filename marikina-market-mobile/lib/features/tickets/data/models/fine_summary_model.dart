import 'package:marikina_market_mobile/core/shared/domain/enums/severity.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/fine_breakdown_item_model.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/fine_summary.dart';

class FineSummaryModel {
  final double? totalPaymentAmount;
  final Severity? highestSeverity;
  final bool allowBloodDonation, allowCommunityService;
  final List<FineBreakdownItemModel> breakdownItems;

  FineSummaryModel({
    required this.totalPaymentAmount,
    required this.highestSeverity,
    required this.breakdownItems,
    this.allowBloodDonation = false,
    this.allowCommunityService = false,
  });

  factory FineSummaryModel.fromJson(Map<String, dynamic> json) {
    return FineSummaryModel(
      totalPaymentAmount: (json['total_payment_amount'] as num?)?.toDouble(),
      highestSeverity: json['highest_severity'] == null
          ? null
          : Severity.fromValue(json['highest_severity']),
      allowBloodDonation: json['allow_blood_donation'] as bool? ?? false,
      allowCommunityService: json['allow_community_service'] as bool? ?? false,
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
      allowBloodDonation: allowBloodDonation,
      allowCommunityService: allowCommunityService,
    );
  }
}
