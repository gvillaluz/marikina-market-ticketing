import 'package:marikina_market_mobile/features/tickets/domain/entities/duplicate_ordinance.dart';

class DuplicateInfoModel {
  final int ordinanceId;
  final String ordinanceNo;
  final String? section;
  final String? specificCategory;

  DuplicateInfoModel({
    required this.ordinanceId,
    required this.ordinanceNo,
    required this.section,
    this.specificCategory,
  });

  factory DuplicateInfoModel.fromJson(Map<String, dynamic> json) {
    return DuplicateInfoModel(
      ordinanceId: (json['ordinanceId'] ?? json['ordinance_id']) as int,
      ordinanceNo: (json['ordinanceNo'] ?? json['ordinance_no']) as String,
      section: json['section'] as String?,
      specificCategory:
          (json['specificCategory'] ?? json['specific_category']) as String?,
    );
  }

  DuplicateOrdinance toEntity() {
    return DuplicateOrdinance(
      ordinanceId: ordinanceId,
      ordinanceNo: ordinanceNo,
      section: section,
      specificCategory: specificCategory,
    );
  }
}
