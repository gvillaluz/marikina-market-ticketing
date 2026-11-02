import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/features/layout/presentation/widgets/root_navigation_bar.dart';

class RootScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const RootScreen({required this.navigationShell, super.key});

  static const List<String> _titles = [
    'Dashboard',
    'Inspections',
    'Tickets',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: navigationShell,
      bottomNavigationBar: RootNavigationBar(navigationShell: navigationShell),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 55,
      leading: Padding(
        padding: const EdgeInsets.only(left: 15),
        child: Image.asset(
          'assets/logo/org_logo.png',
          height: 32,
          width: 32,
          fit: BoxFit.contain,
        ),
      ),

      title: Text(
        _titles[navigationShell.currentIndex],
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: .2,
        ),
      ),

      actions: [
        IconButton(
          tooltip: 'Notifications',
          onPressed: () => context.pushNamed(Routes.notificationsName),
          style: IconButton.styleFrom(
            foregroundColor: AppColors.primary,
            backgroundColor: AppColors.primary.withValues(alpha: .08),
            shape: const CircleBorder(),
          ),
          icon: const Icon(Icons.notifications_outlined, size: 24),
        ),
        const SizedBox(width: 16),
      ],
    );
  }
}
