import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/connectivity/cubit/connectivity_cubit.dart';
import 'package:marikina_market_mobile/core/notification/notification_listener_service.dart';
import 'package:marikina_market_mobile/core/router/mobile_route_access.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/features/auth/data/models/user_model.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_state.dart';

import 'features/auth/data/login_mobile_contract_test.dart'
    show profileResponse, reply;
import 'features/auth/device_registration_test.dart' show accessToken;
import 'features/auth/login_mobile_flow_test.dart' show loginBloc;
import 'features/auth/login_test_network_info.dart';

Authenticated account({
  String role = 'MarketVendor',
  int userId = 1,
  bool mustChangePassword = false,
}) => Authenticated(
  user: UserModel.fromJson({
    ...profileResponse,
    'role': role,
    'userId': userId,
    'mustChangedPassword': mustChangePassword,
  }).toEntity(),
);

const pushMap = <String, Object?>{
  'messageId': 'synthetic-record-update',
  'data': {'ticketId': '42'},
  'notification': {
    'title': 'Record updated',
    'body': 'Your synthetic record was updated.',
  },
};

Future<void> backgroundStub(RemoteMessage message) async {}

Future<void> platformPush(String method) async {
  final completed = Completer<void>();
  TestWidgetsFlutterBinding.instance.channelBuffers.push(
    'plugins.flutter.io/firebase_messaging',
    const StandardMethodCodec().encodeMethodCall(MethodCall(method, pushMap)),
    (_) => completed.complete(),
  );
  await completed.future;
  await Future<void>.value();
}

AuthBloc authSession({bool signedIn = true, Completer<void>? restoreGate}) {
  FlutterSecureStorage.setMockInitialValues({
    if (signedIn) ...{
      'access_token': restoreGate == null
          ? accessToken()
          : 'eyJhbGciOiJIUzI1NiJ9.eyJleHAiOjF9.synthetic',
      'refresh_token': 'synthetic-refresh',
      'refresh_expiration': '2099-01-01T00:00:00Z',
      'user_info_key': jsonEncode(
        UserModel.fromEntity(account().user).toJson(),
      ),
    },
  });
  final connectivity = ConnectivityCubit(LoginTestNetworkInfo());
  addTearDown(connectivity.close);
  final auth = loginBloc(connectivity, (options) async {
    expect(options.path, '/auth/refresh');
    if (restoreGate != null) {
      await restoreGate.future;
    }
    return reply(options, {
      'access_token': accessToken(),
      'refresh_token': 'synthetic-refresh',
      'refresh_token_expiration': '2099-01-01T00:00:00Z',
    });
  });
  addTearDown(() {
    unawaited(auth.close());
  });
  return auth;
}

GoRouter notificationRouter() {
  Widget page(String title) => Scaffold(body: Text(title));
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => page('Home')),
      GoRoute(
        path: '/vendor/records/:ticketId',
        builder: (_, state) =>
            page('Vendor record ${state.pathParameters['ticketId']}'),
      ),
      GoRoute(
        path: '/ticket/:ticketId',
        builder: (_, state) =>
            page('Enforcer ticket ${state.pathParameters['ticketId']}'),
      ),
      GoRoute(
        path: Routes.vendorNotifications,
        builder: (_, _) => page('Vendor inbox'),
      ),
      GoRoute(
        path: Routes.notifications,
        builder: (_, _) => page('Enforcer inbox'),
      ),
    ],
  );
  addTearDown(router.dispose);
  return router;
}

NotificationListenerService listenerFor(
  GoRouter router,
  AuthBloc auth, {
  RemoteMessage? initialMessage,
}) {
  final listener = NotificationListenerService(
    router,
    auth,
    messaging: OpeningMessaging(initialMessage),
  );
  listener.init();
  addTearDown(listener.dispose);
  return listener;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    // Initialize the installed SDK's inbound method-channel handler without
    // starting its Android background isolate or using Firebase credentials.
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    FirebaseMessaging.onBackgroundMessage(backgroundStub);
    debugDefaultTargetPlatformOverride = null;
  });

  test('valid ticket IDs select each role\'s existing detail route', () {
    for (final id in <Object>[42, '42', '2147483647']) {
      final expectedId = id.toString();
      expect(
        MobileRouteAccess.notificationLocation(account(), id),
        '/vendor/records/$expectedId',
      );
      expect(
        MobileRouteAccess.notificationLocation(
          account(role: 'MarketEnforcer'),
          id,
        ),
        '/ticket/$expectedId',
      );
    }
  });

  test('missing or invalid IDs fall back to the role inbox', () {
    for (final id in <Object?>[
      null,
      '',
      'abc',
      0,
      -1,
      '2147483648',
      42.5,
      '../42',
    ]) {
      expect(
        MobileRouteAccess.notificationLocation(account(), id),
        Routes.vendorNotifications,
      );
      expect(
        MobileRouteAccess.notificationLocation(
          account(role: 'MarketEnforcer'),
          id,
        ),
        Routes.notifications,
      );
    }
  });

  test(
    'signed-out, unsupported and mandatory-password sessions cannot open records',
    () {
      for (final state in <AuthState>[
        AuthInitial(),
        AuthLoading(),
        Unauthenticated(false),
        account(role: 'HeadAdmin'),
        account(mustChangePassword: true),
      ]) {
        expect(MobileRouteAccess.notificationLocation(state, '42'), isNull);
      }
      expect(
        MobileRouteAccess.redirect(account(), '/ticket/42'),
        Routes.vendorDashboard,
      );
      expect(
        MobileRouteAccess.redirect(
          account(role: 'MarketEnforcer'),
          '/vendor/records/42',
        ),
        Routes.dashboard,
      );
    },
  );

  test(
    'initial notification waits for session restoration and opens the record',
    () async {
      final gate = Completer<void>();
      final auth = authSession(restoreGate: gate);
      final router = notificationRouter();
      final listener = listenerFor(
        router,
        auth,
        initialMessage: RemoteMessage.fromMap(pushMap),
      );
      final opening = listener.handleInitialMessage();
      await Future<void>.delayed(Duration.zero);
      expect(auth.state, isA<AuthLoading>());
      expect(router.routeInformationProvider.value.uri.path, '/');
      gate.complete();
      await opening.timeout(const Duration(seconds: 3));
      expect(
        router.routeInformationProvider.value.uri.path,
        '/vendor/records/42',
      );
    },
  );

  test(
    'background notification waits for restoration through the same path',
    () async {
      final gate = Completer<void>();
      final auth = authSession(restoreGate: gate);
      final router = notificationRouter();
      listenerFor(router, auth);
      final opened = Completer<void>();
      void onRoute() {
        if (router.routeInformationProvider.value.uri.path ==
                '/vendor/records/42' &&
            !opened.isCompleted) {
          opened.complete();
        }
      }

      router.routeInformationProvider.addListener(onRoute);
      await platformPush('Messaging#onMessageOpenedApp');
      expect(router.routeInformationProvider.value.uri.path, '/');
      gate.complete();
      await opened.future.timeout(const Duration(seconds: 3));
      router.routeInformationProvider.removeListener(onRoute);
      expect(auth.state, isA<Authenticated>());
    },
  );

  test(
    'a signed-out notification is not replayed after a later login',
    () async {
      final auth = authSession(signedIn: false);
      final router = notificationRouter();
      final listener = listenerFor(
        router,
        auth,
        initialMessage: RemoteMessage.fromMap(pushMap),
      );
      await listener.handleInitialMessage().timeout(const Duration(seconds: 3));
      expect(router.routeInformationProvider.value.uri.path, '/');
      final authenticated = auth.stream.firstWhere(
        (state) => state is Authenticated,
      );
      auth.add(UserUpdated(account().user));
      await authenticated;
      expect(router.routeInformationProvider.value.uri.path, '/');
    },
  );

  for (final changeAccount in [false, true]) {
    testWidgets(
      'foreground banner ${changeAccount ? 'ignores a changed account' : 'opens the record when tapped'}',
      (tester) async {
        final auth = (await tester.runAsync(() async => authSession()))!;
        final router = notificationRouter();
        await tester.runAsync(() async {
          listenerFor(router, auth);
        });
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.runAsync(() async {
          if (auth.state is! Authenticated) {
            await auth.stream.firstWhere((state) => state is Authenticated);
          }
        });
        await tester.runAsync(() => platformPush('Messaging#onMessage'));
        await tester.pumpAndSettle();
        expect(find.text('Record updated'), findsOneWidget);
        expect(find.text('Home'), findsOneWidget);
        if (changeAccount) {
          await tester.runAsync(() async {
            final changed = auth.stream.firstWhere(
              (state) => state is Authenticated && state.user.userId == 2,
            );
            auth.add(UserUpdated(account(userId: 2).user));
            await changed;
          });
        }
        await tester.tap(find.text('Record updated'));
        await tester.pumpAndSettle();
        expect(
          find.text(changeAccount ? 'Home' : 'Vendor record 42'),
          findsOneWidget,
        );
        // Let the existing banner's dismissal timer finish before disposing UI.
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}

class OpeningMessaging extends Fake implements FirebaseMessaging {
  final RemoteMessage? initialMessage;
  OpeningMessaging(this.initialMessage);

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Future<RemoteMessage?> getInitialMessage() async => initialMessage;
}
