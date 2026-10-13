import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/utils/date_formatter_util.dart';
import 'package:marikina_market_mobile/features/notification/domain/entities/notification_summary.dart';

class NotificationTile extends StatelessWidget {
  final NotificationSummary notification;
  final ValueChanged<int> onRead;
  final bool isMarkingRead;
  const NotificationTile({
    required this.notification,
    required this.onRead,
    this.isMarkingRead = false,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: notification.isRead ? colors.surface : colors.primaryContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: AppTheme.notificationCardRadius,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isMarkingRead
            ? null
            : () {
                if (!notification.isRead) onRead(notification.notificationId);
                context.pushNamed(
                  Routes.ticketDetailName,
                  pathParameters: {
                    'ticketId': notification.ticketId.toString(),
                  },
                );
              },
        child: Padding(
          padding: AppTheme.notificationCardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppTheme.notificationSmallGap,
                runSpacing: AppTheme.notificationSmallGap,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    size: AppTheme.notificationStatusIconSize,
                    color: colors.primary,
                  ),
                  Text(
                    notification.status.value,
                    style: AppTheme.notificationCaptionStyle.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (!notification.isRead)
                    Text(
                      'Unread',
                      style: AppTheme.notificationCaptionStyle.copyWith(
                        color: colors.primary,
                      ),
                    ),
                  if (isMarkingRead)
                    SizedBox.square(
                      dimension: AppTheme.buttonIconSize,
                      child: CircularProgressIndicator(
                        value: MediaQuery.disableAnimationsOf(context)
                            ? 0.75
                            : null,
                        strokeWidth: AppTheme.buttonProgressStrokeWidth,
                        semanticsLabel: 'Marking notification as read',
                        semanticsValue: 'In progress',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.notificationSmallGap),
              Text(
                'Ticket #${notification.controlNumber} for ${notification.tradeName} is now ${notification.status.value}.',
                style: AppTheme.notificationBodyStyle.copyWith(
                  color: colors.onSurface,
                  fontWeight: notification.isRead
                      ? FontWeight.normal
                      : FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTheme.notificationSmallGap),
              Text(
                DateTimeFormatter.getDateTime(notification.createdAt.toLocal()),
                style: AppTheme.notificationCaptionStyle.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'View ticket',
                  style: AppTheme.notificationCaptionStyle.copyWith(
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
