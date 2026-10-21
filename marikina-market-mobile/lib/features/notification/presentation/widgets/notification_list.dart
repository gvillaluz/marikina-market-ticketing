import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/notification/domain/entities/notification_list_data.dart';
import 'package:marikina_market_mobile/features/notification/presentation/widgets/notification_list_sliver.dart';

class NotificationList extends StatelessWidget {
  final NotificationListData data;
  final ValueChanged<int> onRead;
  final VoidCallback? onRetry;
  const NotificationList({
    required this.data,
    required this.onRead,
    this.onRetry,
    super.key,
  });
  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      SliverPadding(
        padding: AppTheme.notificationListPadding,
        sliver: NotificationListSliver(
          data: data,
          onRead: onRead,
          onRetry: onRetry,
        ),
      ),
    ],
  );
}
