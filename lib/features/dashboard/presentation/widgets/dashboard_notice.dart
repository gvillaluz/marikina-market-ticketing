import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class DashboardNotice extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;

  const DashboardNotice({
    required this.title,
    required this.message,
    required this.icon,
    this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: AppTheme.dashboardCardPadding,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppTheme.dashboardCardRadius,
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: onRetry == null ? colors.primary : colors.error,
            size: AppTheme.dashboardIconSize,
          ),
          const SizedBox(height: AppTheme.dashboardSmallGap),
          Text(
            title,
            style: AppTheme.dashboardHeadingStyle.copyWith(
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: AppTheme.dashboardTinyGap),
          Text(
            message,
            style: AppTheme.dashboardBodyStyle.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppTheme.dashboardSmallGap),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ],
      ),
    );
  }
}
