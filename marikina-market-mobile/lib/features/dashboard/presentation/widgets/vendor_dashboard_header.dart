import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/auth/domain/entities/user.dart';

class VendorDashboardHeader extends StatelessWidget {
  final User user;
  const VendorDashboardHeader({required this.user, super.key});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
        ? 'Good afternoon'
        : 'Good evening';
    return ClipRect(
      child: ColoredBox(
        color: AppTheme.profileHeroColor,
        child: Stack(
          children: [
            Positioned(
              right: -AppTheme.profileHeroCircleSize / 3,
              top: -AppTheme.profileHeroCircleSize / 2,
              child: Container(
                width: AppTheme.profileHeroCircleSize,
                height: AppTheme.profileHeroCircleSize,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.profileHeroOverlay,
                ),
              ),
            ),
            Positioned(
              left: -AppTheme.profileHeroCircleSize / 2,
              bottom: -AppTheme.profileHeroCircleSize / 2,
              child: Container(
                width: AppTheme.profileHeroCircleSize,
                height: AppTheme.profileHeroCircleSize,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.profileHeroOverlay,
                ),
              ),
            ),
            Padding(
              padding: AppTheme.vendorDashboardPadding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greeting, ${user.firstName}',
                          style: MediaQuery.sizeOf(context).width < 320
                              ? AppTheme.sectionHeadingStyle.copyWith(
                                  color: AppTheme.profileHeroForeground,
                                )
                              : AppTheme.profileHeroTitleStyle,
                        ),
                        const SizedBox(height: AppTheme.dashboardTinyGap),
                        Text(
                          user.vendor?.businessName ?? '',
                          style: AppTheme.captionTextStyle.copyWith(
                            color: AppTheme.profileHeroForeground,
                          ),
                        ),
                        const SizedBox(
                          height:
                              AppTheme.dashboardGap +
                              AppTheme.dashboardSmallGap,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Notifications',
                    onPressed: () =>
                        context.goNamed(Routes.vendorNotificationsName),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.profileHeroOverlay,
                      foregroundColor: AppTheme.profileHeroForeground,
                    ),
                    icon: const Icon(Icons.notifications_outlined),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
