import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class DashboardMetricLayout extends StatelessWidget {
  final List<Widget> children;

  const DashboardMetricLayout({required this.children, super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: AppTheme.dashboardSmallGap,
    children: [
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppTheme.dashboardSmallGap,
          children: children
              .take(2)
              .map((child) => Expanded(child: child))
              .toList(),
        ),
      ),
      ...children.skip(2),
    ],
  );
}
