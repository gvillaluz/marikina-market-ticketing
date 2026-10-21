import 'package:marikina_market_mobile/core/shared/domain/entities/community_service_log.dart';

class CommunityServiceLogModel {
  final DateTime serviceDate;
  final double hoursWorked;
  final String proofUrl;

  const CommunityServiceLogModel({
    required this.serviceDate,
    required this.hoursWorked,
    required this.proofUrl,
  });

  factory CommunityServiceLogModel.fromJson(Map<String, Object?> json) {
    return CommunityServiceLogModel(
      serviceDate: DateTime.parse(json['service_date'] as String),
      hoursWorked: (json['hours_worked'] as num).toDouble(),
      proofUrl: json['proof_url'] as String,
    );
  }

  CommunityServiceLog toEntity() => CommunityServiceLog(
    serviceDate: serviceDate,
    hoursWorked: hoursWorked,
    proofUrl: proofUrl,
  );
}
