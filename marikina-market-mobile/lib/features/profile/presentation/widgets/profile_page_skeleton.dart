import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/skeleton_pulse.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class ProfilePageSkeleton extends StatelessWidget {
  const ProfilePageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final shimmerColor = AppTheme.skeletonColor(context);
    return SkeletonPulse(
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Padding(
            padding: AppTheme.profilePagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Profile Header Card Skeleton
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: AppTheme.profileHeaderRadius,
                  ),
                ),
                const SizedBox(height: AppTheme.profileGap),

                // 2. Section Title
                Container(
                  height: 26,
                  width: 200,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: AppTheme.skeletonTextRadius,
                  ),
                ),
                const SizedBox(height: AppTheme.authSmallGap),

                // 3. Section Subtitle
                Container(
                  height: 16,
                  width: 250,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: AppTheme.skeletonTextRadius,
                  ),
                ),
                const SizedBox(height: AppTheme.profileGap),

                // 4. Account Information Rows Container
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    borderRadius: AppTheme.profileCardRadius,
                  ),
                  padding: AppTheme.authPagePadding,
                  child: Column(
                    children: List.generate(5, (index) {
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Field Label placeholder
                              Flexible(
                                child: Container(
                                  height: 14,
                                  width: 90,
                                  decoration: BoxDecoration(
                                    color: shimmerColor,
                                    borderRadius: AppTheme.skeletonTextRadius,
                                  ),
                                ),
                              ),
                              // Field Value placeholder
                              Flexible(
                                child: Container(
                                  height: 14,
                                  width: 130,
                                  decoration: BoxDecoration(
                                    color: shimmerColor,
                                    borderRadius: AppTheme.skeletonTextRadius,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (index < 4) ...[
                            const SizedBox(height: 16),
                            Divider(
                              height: 1,
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],
                      );
                    }),
                  ),
                ),
                const SizedBox(height: AppTheme.profileGap),

                // 5. Edit Account Info Button Skeleton
                Container(
                  height: 48,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: AppTheme.controlRadius,
                  ),
                ),
                const SizedBox(height: AppTheme.profileGap),

                // 6. Change Password Button Skeleton
                Container(
                  height: 48,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: AppTheme.controlRadius,
                  ),
                ),
                const SizedBox(height: AppTheme.skeletonSectionGap),
                const Divider(),
                const SizedBox(height: AppTheme.skeletonSectionGap),

                // 7. Logout Button Skeleton
                Container(
                  height: 48,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: AppTheme.controlRadius,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
