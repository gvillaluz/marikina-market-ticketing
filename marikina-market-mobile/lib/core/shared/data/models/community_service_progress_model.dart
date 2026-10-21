import 'package:marikina_market_mobile/core/shared/data/models/community_service_log_model.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/community_service_progress.dart';

class CommunityServiceProgressModel {
  final int ticketId;
  final int hoursRequired;
  final double hoursCompleted;
  final double hoursRemaining;
  final double completionPercentage;
  final List<CommunityServiceLogModel> entries;

  const CommunityServiceProgressModel({
    required this.ticketId,
    required this.hoursRequired,
    required this.hoursCompleted,
    required this.hoursRemaining,
    required this.completionPercentage,
    required this.entries,
  });

  factory CommunityServiceProgressModel.fromJson(Map<String, Object?> json) {
    return CommunityServiceProgressModel(
      ticketId: json['ticket_id'] as int,
      hoursRequired: (json['hours_required'] as num).toInt(),
      hoursCompleted: (json['hours_completed'] as num).toDouble(),
      hoursRemaining: (json['hours_remaining'] as num).toDouble(),
      completionPercentage: (json['completion_percentage'] as num).toDouble(),
      entries: (json['entries'] as List<Object?>)
          .map(
            (entry) => CommunityServiceLogModel.fromJson(
              entry as Map<String, Object?>,
            ),
          )
          .toList(),
    );
  }

  CommunityServiceProgress toEntity() => CommunityServiceProgress(
    ticketId: ticketId,
    hoursRequired: hoursRequired,
    hoursCompleted: hoursCompleted,
    hoursRemaining: hoursRemaining,
    completionPercentage: completionPercentage,
    entries: entries.map((entry) => entry.toEntity()).toList(),
  );
}
