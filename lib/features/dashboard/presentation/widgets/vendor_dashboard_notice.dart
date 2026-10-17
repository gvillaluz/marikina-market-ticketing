import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class VendorDashboardNotice extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;
  final bool compact;

  const VendorDashboardNotice({
    required this.title,
    required this.message,
    required this.icon,
    this.onRetry,
    this.compact = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: compact
          ? AppTheme.dashboardCompactCardPadding
          : AppTheme.dashboardCardPadding,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppTheme.dashboardCardRadius,
        border: Border.all(color: AppTheme.vendorDashboardCardBorder),
      ),
      child: Column(
        crossAxisAlignment: compact
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: colors.primary,
            size: compact
                ? AppTheme.dashboardIconSize
                : AppTheme.vendorDashboardNoticeIconSize,
          ),
          const SizedBox(height: AppTheme.dashboardSmallGap),
          Text(
            title,
            textAlign: compact ? TextAlign.start : TextAlign.center,
            style: compact
                ? AppTheme.actionTextStyle
                : AppTheme.sectionHeadingStyle,
          ),
          const SizedBox(height: AppTheme.dashboardTinyGap),
          Text(
            message,
            textAlign: compact ? TextAlign.start : TextAlign.center,
            style: AppTheme.bodyTextStyle.copyWith(
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
