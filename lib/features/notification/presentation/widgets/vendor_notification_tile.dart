import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/notification/domain/entities/notification_summary.dart';

class VendorNotificationTile extends StatelessWidget {
  final NotificationSummary notification;
  final ValueChanged<int> onRead;
  final bool isBusy;
  const VendorNotificationTile({
    required this.notification,
    required this.onRead,
    this.isBusy = false,
    super.key,
  });

  String get _title {
    if (notification.isWarning) return 'New written warning';
    if (notification.status == TicketStatus.paid ||
        notification.status == TicketStatus.cleared) {
      return 'Settlement approved';
    }
    if (notification.status == TicketStatus.pending) {
      return 'New violation ticket';
    }
    return 'Ticket status updated';
  }

  IconData get _icon {
    if (notification.isWarning) return Icons.warning_amber_rounded;
    if (notification.status == TicketStatus.paid ||
        notification.status == TicketStatus.cleared) {
      return Icons.check_circle_outline;
    }
    if (notification.status == TicketStatus.pending) {
      return Icons.description_outlined;
    }
    return Icons.assignment_outlined;
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: notification.isRead ? 'Read notification' : 'Unread notification',
    child: Material(
      color: notification.isRead
          ? Colors.white
          : AppTheme.vendorNotificationUnreadBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: AppTheme.vendorNotificationCardRadius,
        side: BorderSide(color: AppTheme.vendorNotificationBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isBusy
            ? null
            : () {
                if (!notification.isRead) onRead(notification.notificationId);
                context.pushNamed(
                  Routes.vendorRecordDetailName,
                  pathParameters: {
                    'ticketId': notification.ticketId.toString(),
                  },
                );
              },
        child: Padding(
          padding: AppTheme.vendorNotificationCardPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _icon,
                size: AppTheme.vendorNotificationIconSize,
                color: AppTheme.vendorNotificationPrimary,
              ),
              const SizedBox(width: AppTheme.vendorNotificationIconGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title,
                      style: AppTheme.vendorNotificationHeadingStyle.copyWith(
                        color: AppTheme.vendorNotificationPrimary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.vendorNotificationTextGap),
                    Text(
                      notification.message,
                      style: AppTheme.vendorNotificationBodyStyle.copyWith(
                        color: AppTheme.vendorNotificationText,
                      ),
                    ),
                    const SizedBox(height: AppTheme.vendorNotificationTextGap),
                    Text(
                      '${notification.isWarning || notification.status == TicketStatus.pending ? 'Issued ' : ''}${DateFormat('dd MMM yyyy · h:mm a').format(notification.createdAt.toLocal())}',
                      style: AppTheme.vendorNotificationCaptionStyle.copyWith(
                        color: AppTheme.vendorNotificationMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppTheme.vendorNotificationTextGap,
                  ),
                  child: isBusy
                      ? const SizedBox.square(
                          dimension: AppTheme.vendorNotificationIconSize,
                          child: CircularProgressIndicator(
                            strokeWidth: AppTheme.buttonProgressStrokeWidth,
                            semanticsLabel: 'Updating notification',
                          ),
                        )
                      : const SizedBox.square(
                          dimension: AppTheme.vendorNotificationDotSize,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppTheme.vendorNotificationUnreadDot,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
