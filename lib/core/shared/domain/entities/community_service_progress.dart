import 'package:marikina_market_mobile/core/shared/domain/entities/community_service_log.dart';

class CommunityServiceProgress {
  final int ticketId;
  final int hoursRequired;
  final double hoursCompleted;
  final double hoursRemaining;
  final double completionPercentage;
  final List<CommunityServiceLog> entries;

  const CommunityServiceProgress({
    required this.ticketId,
    required this.hoursRequired,
    required this.hoursCompleted,
    required this.hoursRemaining,
    required this.completionPercentage,
    required this.entries,
  });
}
