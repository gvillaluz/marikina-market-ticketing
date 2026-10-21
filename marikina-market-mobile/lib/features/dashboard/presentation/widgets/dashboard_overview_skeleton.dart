import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/skeleton_box.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/skeleton_pulse.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/dashboard/presentation/widgets/dashboard_metric_layout.dart';

class DashboardOverviewSkeleton extends StatelessWidget {
  const DashboardOverviewSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const SkeletonPulse(
    child: DashboardMetricLayout(
      children: [
        SkeletonBox(height: AppTheme.dashboardMetricMinHeight, animate: false),
        SkeletonBox(height: AppTheme.dashboardMetricMinHeight, animate: false),
        SkeletonBox(height: AppTheme.dashboardMetricMinHeight, animate: false),
      ],
    ),
  );
}
