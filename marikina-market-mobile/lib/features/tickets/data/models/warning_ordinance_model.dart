import 'package:marikina_market_mobile/features/tickets/domain/entities/warning_ordinance.dart';

class WarningOrdinanceModel {
  final int ordinanceId;
  final String ordinanceNo;
  final String ordinanceCode;

  const WarningOrdinanceModel({
    required this.ordinanceId,
    required this.ordinanceNo,
    required this.ordinanceCode,
  });

  factory WarningOrdinanceModel.fromJson(Map<String, dynamic> json) {
    return WarningOrdinanceModel(
      ordinanceId: json['ordinance_id'] as int,
      ordinanceNo: json['ordinance_no'] as String,
      ordinanceCode: json['ordinance_code'] as String,
    );
  }

  WarningOrdinance toEntity() => WarningOrdinance(
    ordinanceId: ordinanceId,
    ordinanceNo: ordinanceNo,
    ordinanceCode: ordinanceCode,
  );
}
