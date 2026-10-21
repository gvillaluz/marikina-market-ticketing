import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/notification/presentation/widgets/filters.dart';

class NotificationHeader extends StatelessWidget {
  final String filter;
  final ValueChanged<String> onChange;
  const NotificationHeader({
    required this.filter,
    required this.onChange,
    super.key,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Notifications',
        style: AppTheme.pageTitleStyle.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      const SizedBox(height: AppTheme.inspectionTinyGap),
      Text(
        'Keep track of updates to your tickets.',
        style: AppTheme.pageSubtitleStyle.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: AppTheme.notificationGap),
      Filters(filterOption: filter, onChange: onChange),
    ],
  );
}
