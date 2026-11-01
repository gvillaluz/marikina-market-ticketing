import 'package:marikina_market_mobile/core/shared/domain/enums/severity.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/fine_breakdown_item.dart';
import '../../domain/enums/fine_kind.dart';

class FineBreakdownItemModel {
  final int ordinanceId;
  final String ordinanceNo;
  final String? section;
  final String? specificCategory;
  final double? paymentAmount;
  final Severity? severity;
  final FineKind fineKind;
  final double? minimumFine, maximumFine;
  final String? penaltyTerms;
  final bool allowBloodDonation, allowCommunityService;
  final int offenseNumber;
  final bool isDuplicate;

  FineBreakdownItemModel({
    required this.ordinanceId,
    required this.ordinanceNo,
    required this.section,
    this.specificCategory,
    required this.paymentAmount,
    required this.severity,
    required this.offenseNumber,
    required this.isDuplicate,
    this.fineKind = FineKind.unconfirmed,
    this.minimumFine,
    this.maximumFine,
    this.penaltyTerms,
    this.allowBloodDonation = false,
    this.allowCommunityService = false,
  });

  factory FineBreakdownItemModel.fromJson(Map<String, dynamic> json) {
    return FineBreakdownItemModel(
      ordinanceId: json['ordinance_id'] as int,
      ordinanceNo: json['ordinance_no'] as String,
      section: json['section'] as String?,
      specificCategory: json['specific_category'] as String?,
      paymentAmount: (json['payment_amount'] as num?)?.toDouble(),
      severity: json['severity'] == null
          ? null
          : Severity.fromValue(json['severity'] as String),
      fineKind: FineKind.fromValue(json['fine_kind']),
      minimumFine: (json['minimum_fine'] as num?)?.toDouble(),
      maximumFine: (json['maximum_fine'] as num?)?.toDouble(),
      penaltyTerms: json['penalty_terms'] as String?,
      allowBloodDonation: json['allow_blood_donation'] as bool? ?? false,
      allowCommunityService: json['allow_community_service'] as bool? ?? false,
      offenseNumber: json['offense_number'] as int,
      isDuplicate: json['is_duplicate'] as bool,
    );
  }

  FineBreakdownItem toEntity() {
    return FineBreakdownItem(
      ordinanceId: ordinanceId,
      ordinanceNo: ordinanceNo,
      section: section,
      specificCategory: specificCategory,
      paymentAmount: paymentAmount,
      severity: severity,
      offenseNumber: offenseNumber,
      isDuplicate: isDuplicate,
      fineKind: fineKind,
      minimumFine: minimumFine,
      maximumFine: maximumFine,
      penaltyTerms: penaltyTerms,
      allowBloodDonation: allowBloodDonation,
      allowCommunityService: allowCommunityService,
    );
  }
}
