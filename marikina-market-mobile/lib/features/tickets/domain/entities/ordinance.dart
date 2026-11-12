import 'package:marikina_market_mobile/core/shared/domain/enums/severity.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/ordinance_category.dart';
import 'ordinance_penalty_tier.dart';

class Ordinance {
  final int id;
  final String ordinanceNo;
  final String series;
  final String? section;
  final String? specificCategory;
  final String title;
  final String description;
  final OrdinanceCategory category;
  final Severity? severity;
  final bool? warningEligible;
  final List<OrdinancePenaltyTier> penaltyTiers;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final int penaltyTierCount;

  String get sectionLabel => section == null || section!.isEmpty
      ? 'Section unavailable'
      : 'Section $section';

  String get detailsLabel =>
      specificCategory == null || specificCategory!.isEmpty
      ? sectionLabel
      : '$sectionLabel · $specificCategory';

  String get categoryLabel =>
      category == OrdinanceCategory.others &&
          specificCategory != null &&
          specificCategory!.isNotEmpty
      ? specificCategory!
      : category.label;

  Ordinance({
    required this.id,
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
}
