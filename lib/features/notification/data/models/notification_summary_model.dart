import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';
import 'package:marikina_market_mobile/features/notification/domain/entities/notification_summary.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';

class NotificationSummaryModel {
  final int notificationId;
  final int enforcerId;
  final int ticketId;
  final String controlNumber;
  final String tradeName;
  final String marketSection;
  final PenaltyType? penaltyType;
  final double? totalFineAmount;
  final DateTime? dueDate;
  final TicketStatus? status;
  final bool isWarning;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  NotificationSummaryModel({
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
    this.isWarning = false,
  });

  factory NotificationSummaryModel.fromJson(Map<String, Object?> json) {
    return NotificationSummaryModel(
      notificationId: json['id'] as int,
      enforcerId: json['enforcer_id'] as int,
      ticketId: json['ticket_id'] as int,
      controlNumber: json['control_number'] as String,
      tradeName: json['trade_name'] as String,
      marketSection: json['market_section_name'] as String,
      penaltyType: json['penalty_type'] == null
          ? null
          : PenaltyType.fromValue(json['penalty_type'] as String),
      totalFineAmount: (json['total_fine_amount'] as num?)?.toDouble(),
      dueDate: json['due_date'] == null
          ? null
          : DateTime.parse(json['due_date'] as String),
      status: json['status'] == null
          ? null
          : TicketStatus.fromValue(json['status'] as String),
      isWarning: json['type'] == 'Warning',
      message: json['message'] as String,
      isRead: json['is_read'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  NotificationSummary toEntity() {
    return NotificationSummary(
      notificationId: notificationId,
      enforcerId: enforcerId,
      ticketId: ticketId,
      controlNumber: controlNumber,
      tradeName: tradeName,
      marketSection: marketSection,
      penaltyType: penaltyType,
      totalFineAmount: totalFineAmount,
      dueDate: dueDate,
      status: status,
      message: message,
      isRead: isRead,
      createdAt: createdAt,
      isWarning: isWarning,
    );
  }
}
