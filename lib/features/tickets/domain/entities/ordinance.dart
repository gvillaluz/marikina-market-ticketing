import 'package:marikina_market_mobile/core/shared/domain/enums/severity.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/ordinance_category.dart';

class Ordinance {
  final int id;
  final String ordinanceNo;
  final String series;
  final String marketCode;
  final String title;
  final String description;
  final OrdinanceCategory category;
  final Severity severity;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final int penaltyTierCount;

  String get ordinanceCode => marketCode;

  Ordinance({
    required this.id,
    required this.ordinanceNo,
    required this.series,
    required this.marketCode,
    required this.title,
    required this.description,
    required this.category,
    required this.severity,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.penaltyTierCount,
  });
}
