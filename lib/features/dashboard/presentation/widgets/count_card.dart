import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class CountCard extends StatelessWidget {
  final String type;
  final int count;
  final bool compact;

  const CountCard({
    super.key,
    required this.type,
    required this.count,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.dashboardMetricColor(type);
    final label = switch (type) {
      'Ticket' => 'Tickets recorded',
      'Warning' => 'Warnings recorded',
      _ => 'Total this week',
    };
    final icon = switch (type) {
      'Ticket' => Icons.confirmation_num_outlined,
      'Warning' => Icons.warning_amber_outlined,
      _ => Icons.calendar_today_outlined,
    };
    return Semantics(
      label: '$label: $count',
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(
          minHeight: AppTheme.dashboardMetricMinHeight,
        ),
        padding: compact
            ? AppTheme.dashboardCompactCardPadding
            : AppTheme.dashboardCardPadding,
        decoration: BoxDecoration(
          color: AppTheme.dashboardMetricBackground(type),
          borderRadius: AppTheme.dashboardCardRadius,
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (compact) ...[
              Icon(icon, color: color, size: AppTheme.dashboardIconSize),
              const SizedBox(height: AppTheme.dashboardTinyGap),
              Text(
                label,
                style: AppTheme.dashboardBodyStyle.copyWith(color: color),
              ),
            ] else
              Row(
                children: [
                  Icon(icon, color: color, size: AppTheme.dashboardIconSize),
                  const SizedBox(width: AppTheme.dashboardSmallGap),
                  Expanded(
                    child: Text(
                      label,
                      style: AppTheme.dashboardBodyStyle.copyWith(color: color),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: AppTheme.dashboardSmallGap),
            Text(
              '$count',
              style: AppTheme.dashboardCountStyle.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
