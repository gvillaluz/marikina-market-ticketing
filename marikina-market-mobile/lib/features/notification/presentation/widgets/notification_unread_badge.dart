import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class NotificationUnreadBadge extends StatelessWidget {
  final int count;
  const NotificationUnreadBadge({required this.count, super.key});

  @override
  Widget build(BuildContext context) {
    const ring = AppTheme.notificationBadgeRingWidth;
    const size = AppTheme.notificationBadgeHeight + ring * 2;
    return Container(
      constraints: const BoxConstraints(minWidth: size, minHeight: size),
      padding: AppTheme.notificationBadgePadding,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.notificationBadgeColor,
        borderRadius: BorderRadius.circular(size),
        border: Border.all(color: Colors.white, width: ring),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        textScaler: MediaQuery.textScalerOf(
          context,
        ).clamp(maxScaleFactor: AppTheme.notificationBadgeMaxTextScale),
        style: AppTheme.notificationBadgeTextStyle,
      ),
    );
  }
}
