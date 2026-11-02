import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class RootNavigationBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const RootNavigationBar({required this.navigationShell, super.key});

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
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.description_outlined),
          selectedIcon: Icon(Icons.description),
          label: 'Inspections',
        ),
        NavigationDestination(
          icon: Icon(Icons.confirmation_num_outlined),
          selectedIcon: Icon(Icons.confirmation_num),
          label: 'Tickets',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
