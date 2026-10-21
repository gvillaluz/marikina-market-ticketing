import '../../domain/entities/record_violation.dart';

class RecordViolationModel {
  final Map<String, Object?> json;
  const RecordViolationModel._(this.json);
  factory RecordViolationModel.fromJson(Map<String, Object?> json) =>
      RecordViolationModel._(json);
  RecordViolation toEntity() => RecordViolation(
    ordinanceNumber: json['ordinance_no'] as String,
    ordinanceCode: json['ordinance_code'] as String,
    offenseCount: json['offense_count'] as int,
    penaltyAmount: (json['penalty_amount'] as num?)?.toDouble(),
  );
}
