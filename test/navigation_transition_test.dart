import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/router/app_routes.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/layout/presentation/pages/root_screen.dart';

GoRouter navigationRouter() => GoRouter(
  initialLocation: '/branch0',
  routes: [
    StatefulShellRoute(
      builder: (context, state, shell) => RootScreen(navigationShell: shell),
      navigatorContainerBuilder: appRoutes
          .whereType<StatefulShellRoute>()
          .first
          .navigatorContainerBuilder,
      branches: List.generate(
        4,
        (index) => StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/branch$index',
              builder: (context, state) => ListView(
                children: [
                  Text('Branch $index'),
                  TextField(key: ValueKey('input$index')),
                  TextButton(
                    onPressed: () => context.push('/branch$index/detail'),
                    child: const Text('Open detail'),
                  ),
                  ...List.generate(
                    30,
                    (row) =>
                        SizedBox(height: 48, child: Text('Row $index-$row')),
                  ),
                ],
              ),
              routes: [
                GoRoute(
                  path: 'detail',
                  builder: (context, state) => Text('Detail $index'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  ],
);

Future<void> showNavigation(
  WidgetTester tester,
  GoRouter router, {
  bool reduceMotion = false,
}) => tester.pumpWidget(
  MaterialApp.router(
    theme: AppTheme.light,
    routerConfig: router,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: child!,
    ),
  ),
);

Finder navigationLabel(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

void main() {
  testWidgets(
    'tab switch uses subtle movement rather than crossing the screen',
    (tester) async {
      final router = navigationRouter();
      addTearDown(router.dispose);
      await showNavigation(tester, router);
      await tester.pumpAndSettle();
      await tester.tap(navigationLabel('Inspections'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      final during = tester.getTopLeft(find.text('Branch 1'));
      await tester.pumpAndSettle();
      final settled = tester.getTopLeft(find.text('Branch 1'));
      expect((during.dx - settled.dx).abs(), lessThan(8));
      expect((during.dy - settled.dy).abs(), lessThan(12));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tab navigation retains entered text, scroll position, and nested routes',
    (tester) async {
      final router = navigationRouter();
      addTearDown(router.dispose);
      await showNavigation(tester, router);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('input0')),
        'Draft inspection',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.tap(navigationLabel('Inspections'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open detail'));
      await tester.pumpAndSettle();
      await tester.tap(navigationLabel('Dashboard'));
      await tester.pumpAndSettle();
      expect(find.text('Draft inspection'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .pixels;
      await tester.tap(navigationLabel('Tickets'));
      await tester.pumpAndSettle();
      await tester.tap(navigationLabel('Dashboard'));
      await tester.pumpAndSettle();
      expect(
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .pixels,
        position,
      );
      await tester.tap(navigationLabel('Inspections'));
      await tester.pumpAndSettle();
      expect(find.text('Detail 1'), findsOneWidget);
      expect(find.text('Branch 0'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'rapid tab changes and reduced motion settle on the selected branch',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = navigationRouter();
      addTearDown(router.dispose);
      await showNavigation(tester, router);
      await tester.pumpAndSettle();
      for (final label in ['Inspections', 'Tickets', 'Profile', 'Dashboard']) {
        await tester.tap(navigationLabel(label));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 30));
      }
      await tester.pumpAndSettle();
      expect(find.text('Branch 0'), findsOneWidget);
      await showNavigation(tester, router, reduceMotion: true);
      await tester.pumpAndSettle();
      router.go('/branch3');
      await tester.pump();
      await tester.pump();
      expect(find.text('Branch 3'), findsOneWidget);
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'authentication fade honors reduced motion and keeps its route key',
    (tester) async {
      CustomTransitionPage<void>? page;
      final route = appRoutes.whereType<GoRoute>().singleWhere(
        (route) => route.name == Routes.loginName,
      );
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) {
              page =
                  route.pageBuilder!(context, state)
                      as CustomTransitionPage<void>;
              expect(page!.key, state.pageKey);
              return const SizedBox();
            },
          ),
        ],
      );
      addTearDown(router.dispose);
      await showNavigation(tester, router, reduceMotion: true);
      await tester.pumpAndSettle();
      expect(page!.transitionDuration, Duration.zero);
      expect(page!.reverseTransitionDuration, Duration.zero);
    },
  );
}
