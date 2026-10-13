import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/notification/domain/entities/notification_summary.dart';
import 'package:marikina_market_mobile/features/notification/domain/entities/notification_list_data.dart';
import 'package:marikina_market_mobile/features/notification/presentation/widgets/notification_tile.dart';
import 'package:marikina_market_mobile/features/notification/presentation/widgets/notification_notice.dart';
import 'package:marikina_market_mobile/features/notification/presentation/widgets/notification_list_footer.dart';

class NotificationListSliver extends StatelessWidget {
  final NotificationListData data;
  final ValueChanged<int> onRead;
  final VoidCallback? onRetry;
  const NotificationListSliver({
    required this.data,
    required this.onRead,
    this.onRetry,
    super.key,
  });
  Widget _group(
    BuildContext context,
    String title,
    List<NotificationSummary> items,
  ) => SliverMainAxisGroup(
    slivers: [
      SliverToBoxAdapter(
        child: Padding(
          padding: AppTheme.notificationItemPadding,
          child: Text(
            title,
            style: AppTheme.notificationHeadingStyle.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            key: ValueKey(items[index].notificationId),
            padding: AppTheme.notificationItemPadding,
            child: NotificationTile(
              notification: items[index],
              onRead: onRead,
              isMarkingRead: data.markingReadIds.contains(
                items[index].notificationId,
              ),
            ),
          ),
          childCount: items.length,
          findChildIndexCallback: (key) {
            if (key is! ValueKey<int>) return null;
            final index = items.indexWhere(
              (item) => item.notificationId == key.value,
            );
            return index < 0 ? null : index;
          },
        ),
      ),
    ],
  );
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = <NotificationSummary>[];
    final earlier = <NotificationSummary>[];
    for (final item in data.notifications) {
      (DateUtils.isSameDay(item.createdAt.toLocal(), now) ? today : earlier)
          .add(item);
    }
    return SliverMainAxisGroup(
      slivers: [
        if (data.notifications.isEmpty)
          const SliverToBoxAdapter(
            child: NotificationNotice(
              title: 'No notifications',
              message: 'Ticket updates will appear here.',
            ),
          ),
        if (today.isNotEmpty) _group(context, 'Today', today),
        if (earlier.isNotEmpty) _group(context, 'Earlier', earlier),
        SliverToBoxAdapter(
          child: NotificationListFooter(data: data, onRetry: onRetry),
        ),
      ],
    );
  }
}
