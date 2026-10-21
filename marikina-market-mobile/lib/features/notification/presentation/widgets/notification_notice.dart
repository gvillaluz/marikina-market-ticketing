import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class NotificationNotice extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  const NotificationNotice({
    required this.title,
    required this.message,
    this.onRetry,
    super.key,
  });
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: AppTheme.notificationCardPadding,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: AppTheme.notificationCardRadius,
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.notifications_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: AppTheme.notificationGap),
        Text(title, style: AppTheme.notificationHeadingStyle),
        const SizedBox(height: AppTheme.notificationSmallGap),
        Text(
          message,
          style: AppTheme.notificationBodyStyle.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (onRetry != null)
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
      ],
    ),
  );
}
