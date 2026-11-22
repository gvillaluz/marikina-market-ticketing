import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/penalty_options.dart';

class PenaltyOptionsModel {
  final int ticketId;
  final PenaltyType? currentPenaltyType;
  final List<PenaltyType> allowedPenaltyTypes;
  final double? cashFineAmount;
  final int? communityServiceHours;
  final int version;

  const PenaltyOptionsModel({
    required this.ticketId,
    required this.currentPenaltyType,
    required this.allowedPenaltyTypes,
    required this.cashFineAmount,
    required this.communityServiceHours,
    required this.version,
  });

  factory PenaltyOptionsModel.fromJson(Map<String, Object?> json) {
    return PenaltyOptionsModel(
      ticketId: json['ticket_id'] as int,
      currentPenaltyType: json['current_penalty_type'] == null
          ? null
          : PenaltyType.fromValue(json['current_penalty_type'] as String),
      allowedPenaltyTypes: (json['allowed_penalty_types'] as List<Object?>)
          .map((value) => PenaltyType.fromValue(value as String))
          .toList(),
      cashFineAmount: (json['cash_fine_amount'] as num?)?.toDouble(),
      communityServiceHours: (json['community_service_hours'] as num?)?.toInt(),
      version: json['version'] as int,
    );
  }

  PenaltyOptions toEntity() => PenaltyOptions(
    ticketId: ticketId,
    currentPenaltyType: currentPenaltyType,
    allowedPenaltyTypes: allowedPenaltyTypes,
    cashFineAmount: cashFineAmount,
    communityServiceHours: communityServiceHours,
    version: version,
  );
}
