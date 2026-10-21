import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/widgets/back_to_login_button.dart';

void main() {
  testWidgets('back to login fits a narrow card and replaces recovery route', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(280, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      initialLocation: '/recovery',
      routes: [
        GoRoute(
          path: '/recovery',
          builder: (context, state) => const Scaffold(
            body: Padding(
              padding: AppTheme.authCardPadding,
              child: BackToLoginButton(),
            ),
          ),
        ),
        GoRoute(
          path: Routes.login,
          name: Routes.loginName,
          builder: (context, state) =>
              const Scaffold(body: Text('Login destination')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.getCenter(find.byType(TextButton)).dx, 140);
    await tester.tap(find.text('Back to login'));
    await tester.pumpAndSettle();
    expect(find.text('Login destination'), findsOneWidget);
    expect(router.canPop(), isFalse);
  });

  testWidgets('back to login is disabled during a recovery request', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: BackToLoginButton(enabled: false)),
      ),
    );
    expect(
      tester.widget<TextButton>(find.byType(TextButton)).onPressed,
      isNull,
    );
    await tester.tap(find.text('Back to login'));
    expect(tester.takeException(), isNull);
  });
}
