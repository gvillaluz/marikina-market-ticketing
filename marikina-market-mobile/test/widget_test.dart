import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/connectivity/cubit/connectivity_cubit.dart';
import 'package:marikina_market_mobile/core/di/dependency_injection.dart';
import 'package:marikina_market_mobile/core/router/app_router.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:marikina_market_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:marikina_market_mobile/main.dart';

import 'features/auth/login_mobile_flow_test.dart' show loginBloc;
import 'features/auth/login_test_network_info.dart';

void main() {
  testWidgets('signed-out app startup opens login without staff navigation', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    late ConnectivityCubit connectivity;
    late AuthBloc auth;
    await tester.runAsync(() async {
      connectivity = ConnectivityCubit(LoginTestNetworkInfo());
      auth = loginBloc(connectivity, (options) async {
        fail('Signed-out startup must not send an authenticated HTTP request.');
      });
      await auth.stream
          .firstWhere((state) => state is Unauthenticated)
          .timeout(const Duration(seconds: 5));
    });
    addTearDown(connectivity.close);
    addTearDown(auth.close);
    final router = AppRouter(authBloc: auth);
    addTearDown(router.dispose);
    sl.registerSingleton<AuthBloc>(auth);
    sl.registerFactory<ConnectivityCubit>(() => connectivity);
    sl.registerSingleton<AppRouter>(router);
    addTearDown(() async {
      await sl.unregister<AppRouter>();
      await sl.unregister<ConnectivityCubit>();
      await sl.unregister<AuthBloc>();
    });
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(router.router.routeInformationProvider.value.uri.path, Routes.login);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(auth.close);
  });
}
