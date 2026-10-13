import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/notification/domain/entities/notification_list_data.dart';
import 'package:marikina_market_mobile/features/notification/presentation/widgets/notification_notice.dart';

class NotificationListFooter extends StatelessWidget {
  final NotificationListData data;
  final VoidCallback? onRetry;
  const NotificationListFooter({required this.data, this.onRetry, super.key});
  @override
  Widget build(BuildContext context) {
    if (data.isLoadingMore || data.isRefreshing) {
      return Padding(
        padding: AppTheme.notificationCardPadding,
        child: Center(
          child: SizedBox.square(
            dimension: AppTheme.buttonIconSize,
            child: CircularProgressIndicator(
              value: MediaQuery.disableAnimationsOf(context) ? 0.75 : null,
              strokeWidth: AppTheme.buttonProgressStrokeWidth,
              semanticsLabel: data.isLoadingMore
                  ? 'Loading more notifications'
                  : 'Refreshing notifications',
              semanticsValue: 'In progress',
            ),
          ),
        ),
      );
    }
    if (data.errorMessage != null) {
      return NotificationNotice(
        title: data.isLoadMoreError
            ? 'Unable to load more notifications'
            : 'Refresh failed',
        message: data.errorMessage!.trim().isEmpty
            ? 'Please try again.'
            : data.errorMessage!,
        onRetry: onRetry,
      );
    }
    if (!data.hasMore && data.notifications.isNotEmpty) {
      return Padding(
        padding: AppTheme.notificationCardPadding,
        child: Center(
          child: Text(
            'All notifications loaded',
            style: AppTheme.notificationCaptionStyle.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
