import 'package:hive/hive.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/severity.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_model.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ordinance.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/ordinance_category.dart';

part 'ordinance_hive_model.g.dart';

@HiveType(typeId: 0)
class OrdinanceHiveModel extends HiveObject {
  @HiveField(0)
  final int ordinanceId;

  @HiveField(1)
  final String ordinanceNo;

  @HiveField(2)
  final String ordinanceCode;

  @HiveField(3)
  final String title;

  @HiveField(4)
  final String description;

  @HiveField(5)
  final String category;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final String severity;

  // Preserve the original field IDs so existing device caches remain readable.
  @HiveField(8, defaultValue: '')
  final String series;

  @HiveField(9, defaultValue: '')
  final String marketCode;

  @HiveField(10)
  final DateTime? updatedAt;

  @HiveField(11, defaultValue: true)
  final bool isActive;

  @HiveField(12, defaultValue: 0)
  final int penaltyTierCount;

  OrdinanceHiveModel({
    required this.ordinanceId,
    required this.ordinanceNo,
    required this.ordinanceCode,
    required this.title,
    required this.description,
    required this.category,
    required this.createdAt,
    required this.severity,
    this.series = '',
    this.marketCode = '',
    this.updatedAt,
    this.isActive = true,
    this.penaltyTierCount = 0,
  });

  factory OrdinanceHiveModel.fromModel(OrdinanceModel model) {
    return OrdinanceHiveModel(
      ordinanceId: model.ordinanceId,
      ordinanceNo: model.ordinanceNo,
      ordinanceCode: model.marketCode,
      title: model.title,
      description: model.description,
      category: model.category.value,
      createdAt: model.createdAt,
      severity: model.severity.value,
      series: model.series,
      marketCode: model.marketCode,
      updatedAt: model.updatedAt,
      isActive: model.isActive,
      penaltyTierCount: model.penaltyTierCount,
    );
  }

  Ordinance toEntity() {
    return Ordinance(
      id: ordinanceId,
      ordinanceNo: ordinanceNo,
      series: series,
      marketCode: marketCode.isEmpty ? ordinanceCode : marketCode,
      title: title,
      description: description,
      category: OrdinanceCategory.fromValue(category),
      severity: Severity.fromValue(severity),
      createdAt: createdAt,
      updatedAt: updatedAt ?? createdAt,
      isActive: isActive,
      penaltyTierCount: penaltyTierCount,
    );
  }
}
