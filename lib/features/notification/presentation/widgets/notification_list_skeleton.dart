import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/skeleton_pulse.dart';
import 'package:marikina_market_mobile/features/notification/presentation/widgets/notification_skeleton_card.dart';

class NotificationListSkeleton extends StatelessWidget {
  final int itemCount;
  final bool isVendor;
  const NotificationListSkeleton({
    this.itemCount = 5,
    this.isVendor = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final cards = Padding(
        padding: isVendor
            ? AppTheme.vendorNotificationListPadding
            : AppTheme.notificationListPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < itemCount; index++)
              Padding(
                padding: isVendor
                    ? AppTheme.vendorNotificationItemPadding
                    : AppTheme.notificationItemPadding,
                child: NotificationSkeletonCard(
                  key: ValueKey('notification-skeleton-card-$index'),
                ),
              ),
          ],
        ),
      );
      return SkeletonPulse(
        child: ExcludeSemantics(
          child: constraints.hasBoundedHeight
              ? SingleChildScrollView(child: cards)
              : cards,
        ),
      );
    },
  );
}
