import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';

class NotificationSummary {
  final int notificationId;
  final int enforcerId;
  final int ticketId;
  final String controlNumber;
  final String tradeName;
  final String marketSection;
  final PenaltyType penaltyType;
  final double? totalFineAmount;
  final DateTime dueDate;
  final TicketStatus status;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  NotificationSummary({
    required this.notificationId,
    required this.enforcerId,
    required this.ticketId,
    required this.controlNumber,
    required this.tradeName,
    required this.marketSection,
    required this.penaltyType,
    this.totalFineAmount,
    required this.dueDate,
    required this.status,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });
}
