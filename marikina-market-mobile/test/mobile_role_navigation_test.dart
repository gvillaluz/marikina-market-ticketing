import 'package:marikina_market_mobile/features/profile/presentation/pages/profile_page.dart';
import 'package:marikina_market_mobile/features/profile/presentation/bloc/profile_bloc.dart';
import 'features/profile/profile_form_test.dart' show formBloc;
import 'vendor_profile_session_test.dart' show vendorAccount;
import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/connectivity/cubit/connectivity_cubit.dart';
import 'package:marikina_market_mobile/core/di/dependency_injection.dart';
import 'package:marikina_market_mobile/core/router/app_router.dart';
import 'package:marikina_market_mobile/core/router/mobile_route_access.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/login_card_header.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/auth_btn.dart';
import 'package:marikina_market_mobile/features/auth/presentation/widgets/change_password_card.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/auth/data/models/user_model.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:marikina_market_mobile/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:marikina_market_mobile/features/dashboard/data/data_sources/dashboard_remote_data_source.dart';
import 'package:marikina_market_mobile/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:marikina_market_mobile/features/dashboard/domain/use_cases/load_dashboard_summary_use_case.dart';
import 'package:marikina_market_mobile/features/dashboard/presentation/pages/vendor_dashboard_page.dart';
import 'package:marikina_market_mobile/features/dashboard/presentation/bloc/vendor_dashboard_bloc.dart';
import 'vendor_dashboard_test.dart' show vendorDashboardBloc, dashboardResponse;
import 'package:marikina_market_mobile/features/records/data/data_sources/records_remote_data_source.dart';
import 'package:marikina_market_mobile/features/records/data/repositories/records_repository_impl.dart';
import 'package:marikina_market_mobile/features/records/domain/use_cases/load_records_use_case.dart';
import 'package:marikina_market_mobile/features/records/presentation/bloc/records/records_bloc.dart';
import 'package:marikina_market_mobile/features/records/presentation/pages/records_page.dart';
import 'package:marikina_market_mobile/features/auth/domain/enums/role.dart';
import 'package:marikina_market_mobile/features/notification/data/data_sources/notification_remote_data_source.dart';
import 'package:marikina_market_mobile/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:marikina_market_mobile/features/notification/domain/use_cases/load_notifications_use_case.dart';
import 'package:marikina_market_mobile/features/notification/domain/use_cases/load_unread_count_use_case.dart';
import 'package:marikina_market_mobile/features/notification/domain/use_cases/mark_as_read_use_case.dart';
import 'package:marikina_market_mobile/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:marikina_market_mobile/features/notification/presentation/bloc/notification_state.dart';
import 'package:marikina_market_mobile/features/notification/presentation/pages/notification_page.dart';
import 'features/auth/login_mobile_flow_test.dart' show loginBloc, startLogin;
import 'features/auth/login_test_network_info.dart';
import 'features/auth/data/login_mobile_contract_test.dart'
    show profileResponse, otpResponse, tokenResponse, reply, contractClient;
import 'dashboard_ui_test.dart' show summaryResponse;
import 'vendor_notifications_test.dart' show vendorBloc, vendorWarning;

Future<void> authenticate(
  AuthBloc bloc,
  String role, {
  int userId = 1,
  bool mustChangePassword = false,
}) async {
  final finished = bloc.stream.firstWhere(
    (state) =>
        state is Authenticated &&
        state.user.role.value == role &&
        state.user.userId == userId,
  );
  bloc.add(
    UserUpdated(
      UserModel.fromJson({
        ...profileResponse,
        'role': role,
        'userId': userId,
        'mustChangedPassword': mustChangePassword,
      }).toEntity(),
    ),
  );
  await finished.timeout(const Duration(seconds: 5));
}

void registerEnforcerDashboard() {
  final client = contractClient(
    (options) async => reply(options, summaryResponse),
  );
  addTearDown(client.dio.close);
  sl.registerFactory<DashboardBloc>(
    () => DashboardBloc(
      loadDashboardSummaryUseCase: LoadDashboardSummaryUseCase(
        DashboardRepositoryImpl(DashboardRemoteDataSourceImpl(client)),
      ),
    ),
  );
  addTearDown(() => sl.unregister<DashboardBloc>());
}

Future<void> showRoleApp(
  WidgetTester tester,
  AppRouter appRouter,
  AuthBloc auth,
) => tester.pumpWidget(
  MultiBlocProvider(
    providers: [
      BlocProvider.value(value: auth),
      BlocProvider.value(value: auth.connectivityCubit),
    ],
    child: MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: appRouter.router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
    ),
  ),
);

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    final client = contractClient(
      (options) async =>
          reply(options, {'items': [], 'has_more': false, 'total': 0}),
    );
    addTearDown(client.dio.close);
    final dashboardClient = contractClient(
      (options) async => reply(options, dashboardResponse),
    );
    addTearDown(dashboardClient.dio.close);
    sl.registerFactory<VendorDashboardBloc>(
      () => vendorDashboardBloc(dashboardClient),
    );
    addTearDown(() => sl.unregister<VendorDashboardBloc>());
    sl.registerFactory<RecordsBloc>(
      () => RecordsBloc(
        LoadRecordsUseCase(
          RecordsRepositoryImpl(RecordsRemoteDataSource(client)),
        ),
      ),
    );
    addTearDown(() => sl.unregister<RecordsBloc>());
    sl.registerFactory<ProfileBloc>(
      () => formBloc(client),
      instanceName: 'vendorProfile',
    );
    addTearDown(
      () => sl.unregister<ProfileBloc>(instanceName: 'vendorProfile'),
    );
    sl.registerFactory<NotificationBloc>(() {
      final repository = NotificationRepositoryImpl(
        NotificationRemoteDataSourceImpl(client, role: Role.marketVendor),
      );
      return NotificationBloc(
        loadNotificationsUseCase: LoadNotificationsUseCase(repository),
        markAsReadUseCase: MarkAsReadUseCase(repository),
        loadUnreadCountUseCase: LoadUnreadCountUseCase(repository),
      );
    }, instanceName: 'vendorNotifications');
    addTearDown(
      () =>
          sl.unregister<NotificationBloc>(instanceName: 'vendorNotifications'),
    );
  });

  testWidgets(
    'vendor inbox is discarded across accounts and blocked for unsupported roles',
    (tester) async {
      late ConnectivityCubit connectivity;
      late AuthBloc auth;
      late NotificationBloc firstInbox;
      late NotificationBloc secondInbox;
      await tester.runAsync(() async {
        connectivity = ConnectivityCubit(LoginTestNetworkInfo());
        auth = loginBloc(connectivity, (options) async => reply(options, {}));
        await auth.stream.firstWhere((state) => state is Unauthenticated);
        await authenticate(auth, 'MarketVendor');
        firstInbox = vendorBloc(
          (options) async => reply(options, {
            'items': [
              {...vendorWarning, 'message': 'First vendor only'},
            ],
            'has_more': false,
            'total': 1,
          }),
        );
        secondInbox = vendorBloc(
          (options) async => reply(options, {
            'items': [
              {...vendorWarning, 'message': 'Second vendor only'},
            ],
            'has_more': false,
            'total': 1,
          }),
        );
      });
      addTearDown(() async {
        if (!auth.isClosed) await auth.close();
      });
      addTearDown(connectivity.close);
      sl.unregister<NotificationBloc>(instanceName: 'vendorNotifications');
      sl.registerFactory<NotificationBloc>(
        () => (auth.state as Authenticated).user.userId == 1
            ? firstInbox
            : secondInbox,
        instanceName: 'vendorNotifications',
      );
      final appRouter = AppRouter(authBloc: auth);
      var routerDisposed = false;
      addTearDown(() {
        if (!routerDisposed) appRouter.dispose();
      });
      await showRoleApp(tester, appRouter, auth);
      await tester.pumpAndSettle();
      appRouter.router.go(Routes.vendorNotifications);
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        if (firstInbox.state is! NotificationLoaded) {
          await firstInbox.stream.firstWhere((s) => s is NotificationLoaded);
        }
      });
      await tester.pumpAndSettle();
      expect(find.text('First vendor only'), findsOneWidget);
      await tester.runAsync(
        () => authenticate(auth, 'MarketVendor', userId: 2),
      );
      await tester.pumpAndSettle();
      expect(firstInbox.isClosed, isTrue);
      appRouter.router.go(Routes.vendorNotifications);
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        if (secondInbox.state is! NotificationLoaded) {
          await secondInbox.stream.firstWhere((s) => s is NotificationLoaded);
        }
      });
      await tester.pumpAndSettle();
      expect(find.text('First vendor only'), findsNothing);
      expect(find.text('Second vendor only'), findsOneWidget);
      final enforcerState = Authenticated(
        user: UserModel.fromJson(profileResponse).toEntity(),
      );
      expect(
        MobileRouteAccess.redirect(enforcerState, Routes.vendorNotifications),
        Routes.dashboard,
      );
      await tester.runAsync(() => authenticate(auth, 'HeadAdmin', userId: 3));
      await tester.pumpAndSettle();
      appRouter.router.go(Routes.vendorNotifications);
      await tester.pumpAndSettle();
      expect(
        appRouter.router.routeInformationProvider.value.uri.path,
        Routes.mobileAccessUnavailable,
      );
      expect(find.byType(NotificationPage), findsNothing);
      await tester.pumpWidget(const SizedBox());
      appRouter.dispose();
      routerDisposed = true;
      await tester.pump();
      // Match BlocProvider disposal: cancel auth timers and initiate async close.
      unawaited(auth.close());
      expect(auth.isClosed, isTrue);
    },
  );

  testWidgets('login header has no enforcer label or replacement role text', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: LoginCardHeader()),
      ),
    );
    expect(find.text('Enforcer Access'), findsNothing);
    expect(find.text('Vendor Access'), findsNothing);
    expect(
      find.text('Marikina Public Market Inspection System'),
      findsOneWidget,
    );
  });

  testWidgets(
    'vendor OTP login reaches vendor tabs and cannot enter enforcer pages',
    (tester) async {
      tester.view.physicalSize = const Size(280, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final requests = <String>[];
      late ConnectivityCubit connectivity;
      late AuthBloc auth;
      await tester.runAsync(() async {
        connectivity = ConnectivityCubit(LoginTestNetworkInfo());
        auth = loginBloc(connectivity, (options) async {
          requests.add(options.path);
          if (options.path == '/auth/login-mobile') {
            return reply(options, otpResponse);
          }
          if (options.path == '/auth/verify-login-mobile') {
            return reply(options, tokenResponse);
          }
          return reply(options, vendorAccount);
        });
        await startLogin(auth);
      });
      addTearDown(connectivity.close);
      addTearDown(() async {
        if (!auth.isClosed) await auth.close();
      });
      final appRouter = AppRouter(authBloc: auth);
      var routerDisposed = false;
      addTearDown(() {
        if (!routerDisposed) appRouter.dispose();
      });
      await showRoleApp(tester, appRouter, auth);
      await tester.pumpAndSettle();
      expect(
        appRouter.router.routeInformationProvider.value.uri.path,
        Routes.loginOtp,
      );
      await tester.runAsync(() async {
        final authenticated = auth.stream.firstWhere(
          (state) => state is Authenticated,
        );
        auth.add(VerifyLoginSubmitted('001234'));
        await authenticated;
      });
      await tester.pumpAndSettle();
      expect(
        appRouter.router.routeInformationProvider.value.uri.path,
        Routes.vendorDashboard,
      );
      final destinations = tester
          .widgetList<NavigationDestination>(find.byType(NavigationDestination))
          .map((destination) => destination.label);
      expect(destinations, [
        'Dashboard',
        'Records',
        'Notifications',
        'Profile',
      ]);
      final initialRequests = requests.length;
      for (var index = 0; index < 4; index++) {
        await tester.tap(find.byType(NavigationDestination).at(index));
        await tester.pumpAndSettle();
        expect(
          find.byType(
            index == 1
                ? RecordsPage
                : index == 2
                ? NotificationPage
                : index == 3
                ? ProfilePage
                : VendorDashboardPage,
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }
      expect(requests.length, initialRequests);
      for (final path in [
        Routes.newInspection,
        '/ticket/42',
        Routes.notifications,
      ]) {
        appRouter.router.go(path);
        await tester.pumpAndSettle();
        expect(
          appRouter.router.routeInformationProvider.value.uri.path,
          Routes.vendorDashboard,
        );
        expect(find.byType(VendorDashboardPage), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      expect(find.byTooltip('Logout'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      appRouter.dispose();
      routerDisposed = true;
      await tester.pump();
      unawaited(auth.close());
      expect(auth.isClosed, isTrue);
    },
  );

  testWidgets('account changes discard tab stacks and enforce the new role', (
    tester,
  ) async {
    final connectivity = ConnectivityCubit(LoginTestNetworkInfo());
    addTearDown(connectivity.close);
    final auth = loginBloc(connectivity, (options) async => reply(options, {}));
    final appRouter = AppRouter(authBloc: auth);
    final dashboardClient = contractClient(
      (options) async => reply(options, summaryResponse),
    );
    addTearDown(dashboardClient.dio.close);
    final enforcerDashboard = DashboardBloc(
      loadDashboardSummaryUseCase: LoadDashboardSummaryUseCase(
        DashboardRepositoryImpl(DashboardRemoteDataSourceImpl(dashboardClient)),
      ),
    );
    sl.registerFactory<DashboardBloc>(() => enforcerDashboard);
    addTearDown(() => sl.unregister<DashboardBloc>());
    Future<void> updateAccount(String role, {int userId = 1}) async {
      final changed = authenticate(auth, role, userId: userId);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(auth.state, isA<Authenticated>());
      final user = (auth.state as Authenticated).user;
      expect(user.role.value, role);
      expect(user.userId, userId);
      await changed;
    }

    Future<void> settleRoutes() async {
      await tester.pump();
      await tester.runAsync(() => pumpEventQueue());
      await tester.pumpAndSettle();
    }

    try {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(auth.state, isA<Unauthenticated>());
      await updateAccount('MarketVendor');
      await showRoleApp(tester, appRouter, auth);
      await settleRoutes();
      final oldShell = tester.state<State>(
        find.byType(StatefulNavigationShell),
      );
      appRouter.router.go(Routes.vendorRecords);
      await settleRoutes();
      await updateAccount('MarketVendor', userId: 2);
      await settleRoutes();
      expect(
        appRouter.router.routeInformationProvider.value.uri.path,
        Routes.vendorDashboard,
      );
      expect(
        identical(
          oldShell,
          tester.state<State>(find.byType(StatefulNavigationShell)),
        ),
        isFalse,
      );
      appRouter.router.go(Routes.vendorRecords);
      await settleRoutes();
      final sameAccountShell = tester.state<State>(
        find.byType(StatefulNavigationShell),
      );
      await updateAccount('MarketVendor', userId: 2);
      await settleRoutes();
      expect(
        appRouter.router.routeInformationProvider.value.uri.path,
        Routes.vendorRecords,
      );
      expect(
        identical(
          sameAccountShell,
          tester.state<State>(find.byType(StatefulNavigationShell)),
        ),
        isTrue,
      );
      await updateAccount('MarketEnforcer', userId: 3);
      await settleRoutes();
      expect(
        appRouter.router.routeInformationProvider.value.uri.path,
        Routes.dashboard,
      );
      expect(
        tester
            .widgetList<NavigationDestination>(
              find.byType(NavigationDestination),
            )
            .map((destination) => destination.label),
        ['Dashboard', 'Inspections', 'Tickets', 'Profile'],
      );
      appRouter.router.go(Routes.vendorRecords);
      await settleRoutes();
      expect(
        appRouter.router.routeInformationProvider.value.uri.path,
        Routes.dashboard,
      );
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      appRouter.dispose();
      unawaited(auth.close());
      if (!enforcerDashboard.isClosed) unawaited(enforcerDashboard.close());
      await tester.pump();
      await tester.runAsync(() => pumpEventQueue());
      await tester.pump();
    }
  });

  testWidgets(
    'logout and restored enforcer sessions cannot expose prior navigation',
    (tester) async {
      final restoredEnforcer = UserModel.fromJson({
        ...profileResponse,
        'role': 'MarketEnforcer',
      });
      final payload = base64Url
          .encode(
            utf8.encode(
              jsonEncode({
                'exp':
                    DateTime.now()
                        .add(const Duration(days: 1))
                        .millisecondsSinceEpoch ~/
                    1000,
              }),
            ),
          )
          .replaceAll('=', '');
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'eyJhbGciOiJub25lIn0.$payload.test',
        'refresh_token': 'test-refresh-token',
        'device_token': 'test-device-token',
        'refresh_expiration': DateTime.now()
            .add(const Duration(days: 2))
            .toIso8601String(),
        'user_info_key': jsonEncode(restoredEnforcer.toJson()),
      });
      registerEnforcerDashboard();
      late ConnectivityCubit connectivity;
      late AuthBloc auth;
      await tester.runAsync(() async {
        connectivity = ConnectivityCubit(LoginTestNetworkInfo());
        auth = loginBloc(connectivity, (options) async => reply(options, {}));
        await auth.stream
            .firstWhere((state) => state is Authenticated)
            .timeout(const Duration(seconds: 5));
      });
      addTearDown(connectivity.close);
      addTearDown(auth.close);
      final appRouter = AppRouter(authBloc: auth);
      addTearDown(appRouter.dispose);
      await showRoleApp(tester, appRouter, auth);
      await tester.pumpAndSettle();
      expect(
        appRouter.router.routeInformationProvider.value.uri.path,
        Routes.dashboard,
      );
      appRouter.router.go(Routes.vendorProfile);
      await tester.pumpAndSettle();
      expect(
        appRouter.router.routeInformationProvider.value.uri.path,
        Routes.dashboard,
      );
      await tester.runAsync(() async {
        final signedOut = auth.stream
            .firstWhere((state) => state is Unauthenticated)
            .timeout(const Duration(seconds: 5));
        auth.add(LogoutUser(false));
        await signedOut;
      });
      await tester.pumpAndSettle();
      expect(
        appRouter.router.routeInformationProvider.value.uri.path,
        Routes.login,
      );
      appRouter.router.go(Routes.dashboard);
      await tester.pumpAndSettle();
      expect(
        appRouter.router.routeInformationProvider.value.uri.path,
        Routes.login,
      );
      expect(find.byType(NavigationBar), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(auth.close);
    },
  );
  testWidgets(
    'required password update preserves its form and reaches enforcer access after success',
    (tester) async {
      final pending = List.generate(2, (_) => Completer<void>());
      final requests = List.generate(2, (_) => Completer<RequestOptions>());
      var updates = 0;
      registerEnforcerDashboard();
      late ConnectivityCubit connectivity;
      late AuthBloc auth;
      await tester.runAsync(() async {
        connectivity = ConnectivityCubit(LoginTestNetworkInfo());
        auth = loginBloc(connectivity, (options) async {
          expect(options.path, '/auth/mandatory-change-password');
          final index = updates++;
          requests[index].complete(options);
          await pending[index].future;
          if (index == 0) {
            throw DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
            );
          }
          return reply(options, {});
        });
        await auth.stream
            .firstWhere((state) => state is Unauthenticated)
            .timeout(const Duration(seconds: 5));
      });
      addTearDown(connectivity.close);
      addTearDown(auth.close);
      await tester.runAsync(() async {
        await const FlutterSecureStorage().write(
          key: 'user_info_key',
          value: jsonEncode(
            UserModel.fromJson({
              ...profileResponse,
              'role': 'MarketEnforcer',
              'mustChangedPassword': true,
            }).toJson(),
          ),
        );
        await authenticate(auth, 'MarketEnforcer', mustChangePassword: true);
      });
      addTearDown(() {
        for (final response in pending) {
          if (!response.isCompleted) {
            response.complete();
          }
        }
      });
      final appRouter = AppRouter(authBloc: auth);
      addTearDown(appRouter.dispose);
      await showRoleApp(tester, appRouter, auth);
      await tester.pumpAndSettle();
      final originalForm = tester.state<State>(find.byType(ChangePasswordCard));
      await tester.enterText(find.byType(TextField).at(0), 'OldPass123');
      await tester.enterText(find.byType(TextField).at(1), 'NewPass123');
      await tester.enterText(find.byType(TextField).at(2), 'NewPass123');
      final confirm = tester.widget<AuthBtn>(find.byType(AuthBtn)).onPressed!;
      confirm();
      confirm();
      await tester.pump();
      await tester.runAsync(() => pumpEventQueue());
      final firstRequest = await tester.runAsync(
        () => requests[0].future.timeout(const Duration(seconds: 5)),
      );
      await tester.pump();
      expect(updates, 1);
      expect((firstRequest!.data as Map<String, Object?>)['user_id'], 1);
      expect(
        appRouter.router.routeInformationProvider.value.uri.path,
        Routes.mandatoryChangePassword,
      );
      expect(
        identical(
          originalForm,
          tester.state<State>(find.byType(ChangePasswordCard)),
        ),
        isTrue,
      );
      await tester.runAsync(() async {
        final failed = auth.stream.firstWhere(
          (state) => state is AuthChangePasswordNetworkError,
        );
        pending[0].complete();
        await failed.timeout(const Duration(seconds: 5));
      });
      await tester.pumpAndSettle();
      expect(
        appRouter.router.routeInformationProvider.value.uri.path,
        Routes.mandatoryChangePassword,
      );
      expect(
        identical(
          originalForm,
          tester.state<State>(find.byType(ChangePasswordCard)),
        ),
        isTrue,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text,
        'NewPass123',
      );
      tester.widget<AuthBtn>(find.byType(AuthBtn)).onPressed!();
      await tester.pump();
      await tester.runAsync(() => pumpEventQueue());
      final secondRequest = await tester.runAsync(
        () => requests[1].future.timeout(const Duration(seconds: 5)),
      );
      expect(secondRequest, isNotNull);
      await tester.runAsync(() async {
        final success = auth.stream.firstWhere(
          (state) => state is Authenticated && !state.user.mustChangePassword,
        );
        pending[1].complete();
        await success.timeout(const Duration(seconds: 5));
      });
      await tester.pumpAndSettle();
      expect(
        appRouter.router.routeInformationProvider.value.uri.path,
        Routes.dashboard,
      );
      expect(find.text('Your market activity at a glance.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(auth.close);
    },
  );
}
