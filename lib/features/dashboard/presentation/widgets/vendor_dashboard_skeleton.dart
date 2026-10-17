import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/skeleton_box.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/skeleton_pulse.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class VendorDashboardSkeleton extends StatelessWidget {
  const VendorDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading your dashboard',
    liveRegion: true,
    child: SkeletonPulse(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              const card = SkeletonBox(
                height: AppTheme.vendorDashboardTotalsSkeletonHeight,
                animate: false,
              );
              if (constraints.maxWidth < 300 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.3) {
                return const Column(
                  children: [
                    card,
                    SizedBox(height: AppTheme.dashboardSmallGap),
                    card,
                  ],
                );
              }
              return const Row(
                children: [
                  Expanded(child: card),
                  SizedBox(width: AppTheme.dashboardSmallGap),
                  Expanded(child: card),
                ],
              );
            },
          ),
          const SizedBox(height: AppTheme.dashboardGap),
          const Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: AppTheme.vendorDashboardHeadingSkeletonWidth,
              child: SkeletonBox(
                height: AppTheme.vendorDashboardHeadingSkeletonHeight,
                animate: false,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.dashboardSmallGap),
          const SkeletonBox(
            height: AppTheme.vendorDashboardScoreSkeletonHeight,
            animate: false,
          ),
          const SizedBox(height: AppTheme.dashboardGap),
          const Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: AppTheme.vendorDashboardHeadingSkeletonWidth,
              child: SkeletonBox(
                height: AppTheme.vendorDashboardHeadingSkeletonHeight,
                animate: false,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.dashboardSmallGap),
          const SkeletonBox(
            height: AppTheme.vendorDashboardTaskSkeletonHeight,
            animate: false,
          ),
          const SkeletonBox(
            height: AppTheme.vendorDashboardTaskSkeletonHeight,
            animate: false,
          ),
        ],
      ),
    ),
  );
}
