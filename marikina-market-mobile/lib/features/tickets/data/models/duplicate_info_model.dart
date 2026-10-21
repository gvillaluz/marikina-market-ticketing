import 'package:marikina_market_mobile/features/tickets/domain/entities/duplicate_ordinance.dart';

class DuplicateInfoModel {
  final int ordinanceId;
  final String ordinanceNo;
  final String ordinanceCode;

  DuplicateInfoModel({required this.ordinanceId, required this.ordinanceNo, required this.ordinanceCode});

  factory DuplicateInfoModel.fromJson(Map<String, dynamic> json) {
    return DuplicateInfoModel(
      ordinanceId: (json['ordinanceId'] ?? json['ordinance_id']) as int,
      ordinanceNo: (json['ordinanceNo'] ?? json['ordinance_no']) as String,
      ordinanceCode: (json['ordinanceCode'] ?? json['ordinance_code']) as String,
    );
  }

  DuplicateOrdinance toEntity() {
    return DuplicateOrdinance(
      ordinanceId: ordinanceId,
      ordinanceNo: ordinanceNo,
      ordinanceCode: ordinanceCode,
    );
  }
}