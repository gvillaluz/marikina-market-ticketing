import 'package:marikina_market_mobile/core/shared/domain/enums/severity.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ordinance.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/ordinance_category.dart';
import 'ordinance_penalty_tier_model.dart';

class OrdinanceModel {
  final int ordinanceId;
  final String ordinanceNo;
  final String series;
  final String? section;
  final String? specificCategory;
  final String title;
  final String description;
  final OrdinanceCategory category;
  final Severity? severity;
  final bool? warningEligible;
  final List<OrdinancePenaltyTierModel> penaltyTiers;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final int penaltyTierCount;

  OrdinanceModel({
    required this.ordinanceId,
    required this.ordinanceNo,
    required this.series,
    required this.section,
    this.specificCategory,
    required this.title,
    required this.description,
    required this.category,
    required this.severity,
    this.warningEligible,
    this.penaltyTiers = const [],
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.penaltyTierCount,
  });

  factory OrdinanceModel.fromJson(Map<String, Object?> json) {
    return OrdinanceModel(
      ordinanceId: json['id'] as int,
      ordinanceNo: json['ordinance_no'] as String,
      series: json['series'] as String,
      section: json['section'] as String?,
      specificCategory: json['specific_category'] as String?,
      title: json['title'] as String,
      // Legacy cache field; ordinances no longer have a description in the API.
      description: '',
      category: OrdinanceCategory.fromValue(json['category'] as String),
      severity: json['severity'] == null
          ? null
          : Severity.fromValue(json['severity'] as String),
      warningEligible: json['warning_eligible'] as bool?,
      penaltyTiers: (json['penalty_tiers'] as List<Object?>? ?? const [])
          .map(
            (item) => OrdinancePenaltyTierModel.fromJson(
              item as Map<String, Object?>,
            ),
          )
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isActive: json['is_active'] as bool,
      penaltyTierCount: json['penalty_tier_count'] as int,
    );
  }

  Ordinance toEntity() {
    return Ordinance(
      id: ordinanceId,
      ordinanceNo: ordinanceNo,
      series: series,
      section: section,
      specificCategory: specificCategory,
      title: title,
      description: description,
      category: category,
      severity: severity,
      warningEligible: warningEligible,
      penaltyTiers: penaltyTiers.map((tier) => tier.toEntity()).toList(),
      createdAt: createdAt,
      updatedAt: updatedAt,
      isActive: isActive,
      penaltyTierCount: penaltyTierCount,
    );
  }
}
