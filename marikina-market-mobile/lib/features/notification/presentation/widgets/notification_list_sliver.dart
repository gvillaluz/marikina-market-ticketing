import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/notification/domain/entities/notification_summary.dart';
import 'package:marikina_market_mobile/features/notification/domain/entities/notification_list_data.dart';
import 'package:marikina_market_mobile/features/notification/presentation/widgets/notification_tile.dart';
import 'package:marikina_market_mobile/features/notification/presentation/widgets/notification_notice.dart';
import 'package:marikina_market_mobile/features/notification/presentation/widgets/notification_list_footer.dart';
import 'package:marikina_market_mobile/features/notification/presentation/widgets/vendor_notification_tile.dart';

class NotificationListSliver extends StatelessWidget {
  final NotificationListData data;
  final ValueChanged<int> onRead;
  final VoidCallback? onRetry;
  final bool isVendor;
  final bool isBusy;
  final bool useVendorStyle;
  const NotificationListSliver({
    required this.data,
    required this.onRead,
    this.onRetry,
    this.isVendor = false,
    this.isBusy = false,
    this.useVendorStyle = false,
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
    if (data.notifications.isEmpty) {
      return SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: NotificationNotice(
              title: 'No notifications',
              message: isVendor
                  ? 'Updates to your market inspection records will appear here.'
                  : 'Ticket updates will appear here.',
            ),
          ),
          SliverToBoxAdapter(
            child: NotificationListFooter(data: data, onRetry: onRetry),
          ),
        ],
      );
    }
    if (isVendor || useVendorStyle) {
      return SliverMainAxisGroup(
        slivers: [
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = data.notifications[index];
              return Padding(
                key: ValueKey(item.notificationId),
                padding: AppTheme.vendorNotificationItemPadding,
                child: VendorNotificationTile(
                  notification: item,
                  isVendor: isVendor,
                  onRead: onRead,
                  isBusy:
                      isBusy ||
                      data.isRefreshing ||
                      data.isLoadingMore ||
                      data.markingReadIds.contains(item.notificationId),
                ),
              );
            }, childCount: data.notifications.length),
          ),
          SliverToBoxAdapter(
            child:
                data.hasMore &&
                    !data.isLoadingMore &&
                    !data.isRefreshing &&
                    data.errorMessage == null
                ? TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: AppTheme.vendorNotificationFooterMinSize,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: isBusy ? null : onRetry,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            'Scroll for earlier notifications',
                            textAlign: TextAlign.center,
                            style: AppTheme.vendorNotificationCountStyle
                                .copyWith(
                                  color: AppTheme.vendorNotificationMuted,
                                ),
                          ),
                        ),
                        const SizedBox(
                          width: AppTheme.vendorNotificationIconGap,
                        ),
                        const Icon(
                          Icons.arrow_downward,
                          size: AppTheme.vendorNotificationIconSize,
                          color: AppTheme.vendorNotificationMuted,
                        ),
                      ],
                    ),
                  )
                : NotificationListFooter(data: data, onRetry: onRetry),
          ),
        ],
      );
    }
    final now = DateTime.now();
    final today = <NotificationSummary>[];
    final earlier = <NotificationSummary>[];
    for (final item in data.notifications) {
      (DateUtils.isSameDay(item.createdAt.toLocal(), now) ? today : earlier)
          .add(item);
    }
    return SliverMainAxisGroup(
      slivers: [
        if (today.isNotEmpty) _group(context, 'Today', today),
        if (earlier.isNotEmpty) _group(context, 'Earlier', earlier),
        SliverToBoxAdapter(
          child: NotificationListFooter(data: data, onRetry: onRetry),
        ),
      ],
    );
  }
}
