import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Dashboard',
        style: AppTheme.dashboardTitleStyle.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      const SizedBox(height: AppTheme.dashboardTinyGap),
      Text(
        'Your market activity at a glance.',
        style: AppTheme.dashboardBodyStyle.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}
