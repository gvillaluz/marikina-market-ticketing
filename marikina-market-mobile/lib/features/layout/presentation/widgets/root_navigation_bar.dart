import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class RootNavigationBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final bool isVendor;
  const RootNavigationBar({
    required this.navigationShell,
    this.isVendor = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      animationDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : AppTheme.tabTransitionDuration,
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) {
        navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        );
      },
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.description_outlined),
          selectedIcon: Icon(Icons.description),
          label: isVendor ? 'Records' : 'Inspections',
        ),
        NavigationDestination(
          icon: Icon(
            isVendor
                ? Icons.notifications_outlined
                : Icons.confirmation_num_outlined,
          ),
          selectedIcon: Icon(
            isVendor ? Icons.notifications : Icons.confirmation_num,
          ),
          label: isVendor ? 'Notifications' : 'Tickets',
        ),
        const NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
