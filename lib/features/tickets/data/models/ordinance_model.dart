import 'package:marikina_market_mobile/core/shared/domain/enums/severity.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ordinance.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/ordinance_category.dart';

class OrdinanceModel {
  final int ordinanceId;
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

  OrdinanceModel({
    required this.ordinanceId,
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

  factory OrdinanceModel.fromJson(Map<String, Object?> json) {
    return OrdinanceModel(
      ordinanceId: json['id'] as int,
      ordinanceNo: json['ordinance_no'] as String,
      series: json['series'] as String,
      marketCode: json['market_code'] as String,
      title: json['title'] as String,
      // Legacy cache field; ordinances no longer have a description in the API.
      description: '',
      category: OrdinanceCategory.fromValue(json['category'] as String),
      severity: Severity.fromValue(json['severity'] as String),
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
      marketCode: marketCode,
      title: title,
      description: description,
      category: category,
      severity: severity,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isActive: isActive,
      penaltyTierCount: penaltyTierCount,
    );
  }
}
