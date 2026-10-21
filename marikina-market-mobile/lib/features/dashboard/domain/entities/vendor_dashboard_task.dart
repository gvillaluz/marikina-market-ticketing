import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';

class VendorDashboardTask {
  final int ticketId;
  final String? controlNumber;
  final PenaltyType penaltyType;
  final int? hoursRequired;
  final double hoursCompleted;

  const VendorDashboardTask({
    required this.ticketId,
    required this.controlNumber,
    required this.penaltyType,
    required this.hoursRequired,
    required this.hoursCompleted,
  });

  double get progress => hoursRequired != null && hoursRequired! > 0
      ? (hoursCompleted / hoursRequired!).clamp(0, 1).toDouble()
      : 0;
}
