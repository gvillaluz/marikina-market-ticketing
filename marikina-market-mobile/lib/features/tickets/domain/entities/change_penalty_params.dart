import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/penalty_change_reason.dart';

class ChangePenaltyParams {
  final int ticketId;
  final PenaltyType penaltyType;
  final int? communityServiceHours;
  final PenaltyChangeReason reason;
  final int version;

  const ChangePenaltyParams({
    required this.ticketId,
    required this.penaltyType,
    required this.communityServiceHours,
    required this.reason,
    required this.version,
  });
}
