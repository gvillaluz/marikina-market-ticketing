import 'package:marikina_market_mobile/features/tickets/domain/entities/warning_ordinance.dart';

class WarningOrdinanceModel {
  final int ordinanceId;
  final String ordinanceNo;
  final String? section;
  final String? specificCategory;

  const WarningOrdinanceModel({
    required this.ordinanceId,
    required this.ordinanceNo,
    required this.section,
    this.specificCategory,
  });

  factory WarningOrdinanceModel.fromJson(Map<String, dynamic> json) {
    return WarningOrdinanceModel(
      ordinanceId: json['ordinance_id'] as int,
      ordinanceNo: json['ordinance_no'] as String,
      section: json['section'] as String?,
      specificCategory: json['specific_category'] as String?,
    );
  }

  WarningOrdinance toEntity() => WarningOrdinance(
    ordinanceId: ordinanceId,
    ordinanceNo: ordinanceNo,
    section: section,
    specificCategory: specificCategory,
  );
}
