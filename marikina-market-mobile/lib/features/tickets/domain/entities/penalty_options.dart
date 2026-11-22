import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';

class PenaltyOptions {
  final int ticketId;
  final PenaltyType? currentPenaltyType;
  final List<PenaltyType> allowedPenaltyTypes;
  final double? cashFineAmount;
  final int? communityServiceHours;
  final int version;

  const PenaltyOptions({
    required this.ticketId,
    required this.currentPenaltyType,
    required this.allowedPenaltyTypes,
    required this.cashFineAmount,
    required this.communityServiceHours,
    required this.version,
  });
}
