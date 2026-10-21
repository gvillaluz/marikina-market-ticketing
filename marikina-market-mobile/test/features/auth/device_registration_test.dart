import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/connectivity/cubit/connectivity_cubit.dart';
import 'package:marikina_market_mobile/core/network/client.dart';
import 'package:marikina_market_mobile/core/notification/notification_listener_service.dart';
import 'package:marikina_market_mobile/core/storage/secure_storage_service_impl.dart';
import 'package:marikina_market_mobile/features/auth/data/data_sources/auth_local_data_source.dart';
import 'package:marikina_market_mobile/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:marikina_market_mobile/features/auth/data/models/user_model.dart';
import 'package:marikina_market_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:marikina_market_mobile/features/auth/domain/services/token_service_impl.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/check_auth_status_use_case.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/login_user_use_case.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/logout_user_use_case.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/mandatory_change_password_use_case.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/refresh_tokens_use_case.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/register_device_token_use_case.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/sync_pending_logouts_use_case.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/verify_login_use_case.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_state.dart';

import 'data/login_mobile_contract_test.dart'
    show contractClient, profileResponse, otpResponse, reply;
import 'logout_test_network_info.dart';

const storage = FlutterSecureStorage();

String accessToken() {
  final payload = base64Url
      .encode(utf8.encode('{"exp":4070908800}'))
      .replaceAll('=', '');
  return 'eyJhbGciOiJIUzI1NiJ9.$payload.synthetic-signature';
}

void seedSession({
  String role = 'MarketVendor',
  bool signedIn = true,
  bool pendingLogout = false,
}) {
  FlutterSecureStorage.setMockInitialValues({
    if (signedIn) ...{
      'access_token': accessToken(),
      'refresh_token': 'synthetic-current-refresh',
      'refresh_expiration': '2099-01-01T00:00:00Z',
      'user_info_key': jsonEncode(
        UserModel.fromJson({...profileResponse, 'role': role}).toJson(),
      ),
    },
    if (pendingLogout)
      'pending_logouts': jsonEncode([
        {
          'device_token': 'synthetic-device-before-switch',
          'refresh_token': 'synthetic-previous-refresh',
        },
      ]),
  });
}

({AuthBloc bloc, AuthRepositoryImpl repository, ApiClient client}) startSession(
  DeviceMessaging messaging,
  Future<Response<Object?>> Function(RequestOptions) respond, {
  LogoutTestNetworkInfo? network,
}) {
  final activeNetwork = network ?? LogoutTestNetworkInfo();
  final client = contractClient(respond);
  addTearDown(client.dio.close);
  final repository = AuthRepositoryImpl(
    localDataSource: AuthLocalDataSourceImpl(
      storageService: const SecureStorageServiceImpl(storage: storage),
      messaging: messaging,
    ),
    remoteDataSource: AuthRemoteDataSourceImpl(apiClient: client),
    tokenService: TokenServiceImpl(),
    networkInfo: activeNetwork,
  );
  final connectivity = ConnectivityCubit(activeNetwork);
  addTearDown(connectivity.close);
  final bloc = AuthBloc(
    connectivityCubit: connectivity,
    checkAuthStatusUseCase: CheckAuthStatusUseCase(repository),
    loginUserUseCase: LoginUserUseCase(repository),
    verifyLoginUseCase: VerifyLoginUseCase(repository),
    logoutUserUseCase: LogoutUserUseCase(repository),
    mandatoryChangePasswordUseCase: MandatoryChangePasswordUseCase(repository),
    refreshTokensUseCase: RefreshTokensUseCase(repository),
    registerDeviceTokenUseCase: RegisterDeviceTokenUseCase(repository),
    syncPendingLogoutsUseCase: SyncPendingLogoutsUseCase(repository),
  );
  addTearDown(bloc.close);
  final router = GoRouter(
    routes: [GoRoute(path: '/', builder: (_, _) => const SizedBox())],
  );
  addTearDown(router.dispose);
  final listener = NotificationListenerService(
    router,
    bloc,
    messaging: messaging,
  );
  listener.init();
  addTearDown(listener.dispose);
  return (bloc: bloc, repository: repository, client: client);
}

Future<void> settleWork(AuthRepositoryImpl repository) async {
  await Future<void>.delayed(Duration.zero);
  await repository.syncPendingLogouts();
  await Future<void>.delayed(Duration.zero);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final role in ['MarketVendor', 'MarketEnforcer']) {
    test(
      'restored $role session registers without waiting for reconnect',
      () async {
        seedSession(role: role);
        final messaging = DeviceMessaging();
        addTearDown(messaging.changes.close);
        final registered = Completer<void>();
        final session = startSession(messaging, (options) async {
          expect(options.path, '/user/device-token');
          expect(options.data, {'device_token': 'synthetic-device-current'});
          expect(options.headers['Authorization'], 'Bearer ${accessToken()}');
          if (!registered.isCompleted) registered.complete();
          return reply(options, {'message': 'Device token registered.'});
        });
        await session.bloc.stream.firstWhere((state) => state is Authenticated);
        await registered.future.timeout(const Duration(seconds: 2));
        expect(
          await storage.read(key: 'device_token'),
          'synthetic-device-current',
        );
        expect(session.bloc.state, isA<Authenticated>());
      },
    );
  }

  test(
    'fresh login registers after OTP without waiting for another auth event',
    () async {
      seedSession(signedIn: false);
      final messaging = DeviceMessaging();
      addTearDown(messaging.changes.close);
      final registered = Completer<void>();
      final session = startSession(messaging, (options) async {
        switch (options.path) {
          case '/auth/login-mobile':
            return reply(options, otpResponse);
          case '/auth/verify-login-mobile':
            return reply(options, {
              'access_token': accessToken(),
              'refresh_token': 'synthetic-current-refresh',
              'refresh_token_expiration': '2099-01-01T00:00:00Z',
            });
          case '/user/me':
            return reply(options, {...profileResponse, 'role': 'MarketVendor'});
          default:
            expect(options.path, '/user/device-token');
            if (!registered.isCompleted) registered.complete();
            return reply(options, {'message': 'Device token registered.'});
        }
      });
      await session.bloc.stream.firstWhere((state) => state is Unauthenticated);
      final pending = session.bloc.stream.firstWhere(
        (state) => state is LoginOtpPending,
      );
      session.bloc.add(
        LoginSubmitted(username: 'vendor01', password: 'SyntheticPass123'),
      );
      await pending;
      final authenticated = session.bloc.stream.firstWhere(
        (state) => state is Authenticated,
      );
      session.bloc.add(VerifyLoginSubmitted('123456'));
      await authenticated;
      await registered.future.timeout(const Duration(seconds: 2));
      expect(
        await storage.read(key: 'device_token'),
        'synthetic-device-current',
      );
    },
  );

  test(
    'Firebase token change registers and securely caches the replacement',
    () async {
      seedSession();
      final messaging = DeviceMessaging();
      addTearDown(messaging.changes.close);
      final replacement = Completer<void>();
      final session = startSession(messaging, (options) async {
        expect(options.path, '/user/device-token');
        if ((options.data as Map)['device_token'] ==
            'synthetic-device-replacement') {
          replacement.complete();
        }
        return reply(options, {'message': 'Device token registered.'});
      });
      await session.bloc.stream.firstWhere((state) => state is Authenticated);
      await settleWork(session.repository);
      messaging.token = 'synthetic-device-replacement';
      messaging.changes.add(messaging.token);
      await replacement.future.timeout(const Duration(seconds: 2));
      expect(
        await storage.read(key: 'device_token'),
        'synthetic-device-replacement',
      );
      expect(
        await storage.read(key: 'refresh_token'),
        'synthetic-current-refresh',
      );
    },
  );

  for (final status in <int?>[null, 503]) {
    test(
      'registration failure $status preserves login and retries on reconnect',
      () async {
        seedSession();
        final messaging = DeviceMessaging();
        addTearDown(messaging.changes.close);
        final changes = StreamController<List<ConnectivityResult>>();
        addTearDown(changes.close);
        final network = LogoutTestNetworkInfo(changes: changes.stream);
        final attempted = Completer<void>();
        final recovered = Completer<void>();
        var fail = true;
        final session = startSession(messaging, (options) async {
          if (options.path == '/auth/refresh') {
            return reply(options, {
              'access_token': accessToken(),
              'refresh_token': 'synthetic-current-refresh',
              'refresh_token_expiration': '2099-01-01T00:00:00Z',
            });
          }
          expect(options.path, '/user/device-token');
          if (fail) {
            if (!attempted.isCompleted) attempted.complete();
            throw DioException(
              requestOptions: options,
              type: status == null
                  ? DioExceptionType.connectionError
                  : DioExceptionType.badResponse,
              response: status == null
                  ? null
                  : Response<Object?>(
                      requestOptions: options,
                      statusCode: status,
                      data: {'message': 'Registration unavailable.'},
                    ),
            );
          }
          if (!recovered.isCompleted) recovered.complete();
          return reply(options, {'message': 'Device token registered.'});
        }, network: network);
        await session.bloc.stream.firstWhere((state) => state is Authenticated);
        await attempted.future.timeout(const Duration(seconds: 2));
        await settleWork(session.repository);
        expect(session.bloc.state, isA<Authenticated>());
        expect(
          await storage.read(key: 'refresh_token'),
          'synthetic-current-refresh',
        );
        network.online = false;
        changes.add([ConnectivityResult.none]);
        await Future<void>.delayed(Duration.zero);
        fail = false;
        network.online = true;
        changes.add([ConnectivityResult.wifi]);
        await recovered.future.timeout(const Duration(seconds: 2));
        await session.bloc.refreshTokensUseCase.waitForOngoingRefresh();
        expect(session.bloc.state, isA<Authenticated>());
      },
    );
  }

  test(
    'permission denial preserves session; later token change can register',
    () async {
      seedSession();
      final messaging = DeviceMessaging()
        ..authorization = AuthorizationStatus.denied;
      addTearDown(messaging.changes.close);
      var posts = 0;
      final registered = Completer<void>();
      final session = startSession(messaging, (options) async {
        posts++;
        if (!registered.isCompleted) registered.complete();
        return reply(options, {'message': 'Device token registered.'});
      });
      await session.bloc.stream.firstWhere((state) => state is Authenticated);
      await settleWork(session.repository);
      expect(posts, 0);
      expect(messaging.permissionCalls, greaterThan(0));
      expect(session.bloc.state, isA<Authenticated>());
      expect(
        await storage.read(key: 'refresh_token'),
        'synthetic-current-refresh',
      );
      messaging.authorization = AuthorizationStatus.authorized;
      messaging.changes.add(messaging.token);
      await registered.future.timeout(const Duration(seconds: 2));
    },
  );

  test('signed-out token changes do not prompt or register', () async {
    seedSession(signedIn: false);
    final messaging = DeviceMessaging();
    addTearDown(messaging.changes.close);
    var posts = 0;
    final session = startSession(messaging, (options) async {
      posts++;
      return reply(options, {});
    });
    await session.bloc.stream.firstWhere((state) => state is Unauthenticated);
    messaging.changes.add(messaging.token);
    await settleWork(session.repository);
    expect(posts, 0);
    expect(messaging.permissionCalls, 0);
  });

  test(
    'logout after in-flight registration removes binding without recreation',
    () async {
      seedSession();
      final messaging = DeviceMessaging();
      addTearDown(messaging.changes.close);
      final registering = Completer<void>();
      final release = Completer<void>();
      final calls = <String>[];
      final session = startSession(messaging, (options) async {
        if (options.path == '/user/device-token') {
          calls.add('register:${(options.data as Map)['device_token']}');
          if (!registering.isCompleted) registering.complete();
          await release.future;
        } else {
          expect(options.path, '/Auth/logout');
          expect(options.data, {
            'device_token': 'synthetic-device-current',
            'refresh_token': 'synthetic-current-refresh',
          });
          calls.add('logout');
        }
        return reply(options, {'message': 'Confirmed.'});
      });
      await session.bloc.stream.firstWhere((state) => state is Authenticated);
      await registering.future.timeout(const Duration(seconds: 2));
      final signedOut = session.bloc.stream.firstWhere(
        (state) => state is Unauthenticated,
      );
      session.bloc.add(LogoutUser(false));
      await Future<void>.delayed(Duration.zero);
      messaging.token = 'synthetic-after-logout';
      messaging.changes.add(messaging.token);
      release.complete();
      await signedOut.timeout(const Duration(seconds: 2));
      await settleWork(session.repository);
      expect(calls, ['register:synthetic-device-current', 'logout']);
      expect(await storage.read(key: 'refresh_token'), isNull);
    },
  );

  test(
    'previous account logout must succeed before new account registration',
    () async {
      seedSession(pendingLogout: true);
      final messaging = DeviceMessaging();
      addTearDown(messaging.changes.close);
      var allowLogout = false;
      final calls = <String>[];
      final registered = Completer<void>();
      final session = startSession(messaging, (options) async {
        if (options.path == '/Auth/logout') {
          expect(options.data, {
            'device_token': 'synthetic-device-before-switch',
            'refresh_token': 'synthetic-previous-refresh',
          });
          if (!allowLogout) {
            throw DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              response: Response<Object?>(
                requestOptions: options,
                statusCode: 503,
                data: {'message': 'Try later.'},
              ),
            );
          }
          calls.add('previous-logout');
        } else {
          expect(options.path, '/user/device-token');
          expect(options.headers['Authorization'], 'Bearer ${accessToken()}');
          calls.add('current-registration');
          if (!registered.isCompleted) registered.complete();
        }
        return reply(options, {'message': 'Confirmed.'});
      });
      await session.bloc.stream.firstWhere((state) => state is Authenticated);
      await settleWork(session.repository);
      expect(calls, isEmpty);
      expect(await storage.read(key: 'pending_logouts'), isNotNull);
      allowLogout = true;
      messaging.changes.add(messaging.token);
      await registered.future.timeout(const Duration(seconds: 2));
      expect(calls, ['previous-logout', 'current-registration']);
      expect(await storage.read(key: 'pending_logouts'), isNull);
    },
  );
}

// Only the external Firebase SDK boundary is faked; app layers run normally.
class DeviceMessaging extends Fake implements FirebaseMessaging {
  String token = 'synthetic-device-current';
  int permissionCalls = 0;
  AuthorizationStatus authorization = AuthorizationStatus.authorized;
  final changes = StreamController<String>.broadcast();

  @override
  Stream<String> get onTokenRefresh => changes.stream;

  @override
  Future<String?> getToken({
    String? vapidKey,
    String? serviceWorkerScriptPath,
  }) async => token;

  @override
  Future<NotificationSettings> requestPermission({
    bool alert = true,
    bool announcement = false,
    bool badge = true,
    bool carPlay = false,
    bool criticalAlert = false,
    bool provisional = false,
    bool sound = true,
    bool providesAppNotificationSettings = false,
  }) async {
    permissionCalls++;
    return NotificationSettings(
      authorizationStatus: authorization,
      alert: AppleNotificationSetting.notSupported,
      announcement: AppleNotificationSetting.notSupported,
      badge: AppleNotificationSetting.notSupported,
      carPlay: AppleNotificationSetting.notSupported,
      lockScreen: AppleNotificationSetting.notSupported,
      notificationCenter: AppleNotificationSetting.notSupported,
      showPreviews: AppleShowPreviewSetting.notSupported,
      timeSensitive: AppleNotificationSetting.notSupported,
      criticalAlert: AppleNotificationSetting.notSupported,
      sound: AppleNotificationSetting.notSupported,
      providesAppNotificationSettings: AppleNotificationSetting.notSupported,
    );
  }
}
