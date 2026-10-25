import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/features/auth/presentation/widgets/login_card.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_event.dart';
import '../login_mobile_flow_test.dart' show loginBloc;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:marikina_market_mobile/core/connectivity/cubit/connectivity_cubit.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/check_auth_status_use_case.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/login_user_use_case.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/logout_user_use_case.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/mandatory_change_password_use_case.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/refresh_tokens_use_case.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/register_device_token_use_case.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/sync_pending_logouts_use_case.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/verify_login_use_case.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:marikina_market_mobile/core/errors/failure.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/network/client.dart';
import 'package:marikina_market_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import '../logout_test_network_info.dart';
import 'login_mobile_contract_test.dart'
    show contractClient, contractRepository, reply;

const storage = FlutterSecureStorage();
const session = <String, String>{
  'access_token': 'expired-access',
  'refresh_token': 'test-refresh-token',
  'user_info_key': 'cached-private-profile',
  'device_token': 'test-device-token',
};

AuthRepositoryImpl logoutRepository(
  ApiClient client,
  LogoutTestNetworkInfo network,
) {
  final repository = contractRepository(client);
  return AuthRepositoryImpl(
    localDataSource: repository.localDataSource,
    remoteDataSource: repository.remoteDataSource,
    tokenService: repository.tokenService,
    networkInfo: network,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({...session}));

  testWidgets('logout validation feedback remains visible after navigation', (
    tester,
  ) async {
    final received = <RequestOptions>[];
    final connectivity = ConnectivityCubit(LogoutTestNetworkInfo());
    addTearDown(connectivity.close);
    final bloc = loginBloc(connectivity, (options) async {
      received.add(options);
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response<Object?>(
          requestOptions: options,
          statusCode: 400,
          data: {'message': 'Device token is invalid.'},
        ),
      );
    });
    try {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(bloc.state, isA<Unauthenticated>());
      expect(received, isEmpty);
      bloc.add(LogoutUser(false));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(bloc.state, isA<AuthConnectionError>());
      expect(
        (bloc.state as AuthConnectionError).message,
        'Device token is invalid.',
      );
      expect(received, hasLength(1));
      final request = received.single;
      expect(request.method, 'POST');
      expect(request.path, '/Auth/logout');
      expect(request.headers.containsKey('Authorization'), isFalse);
      expect(request.extra['skipAuth'], isTrue);
      expect(request.contentType, Headers.jsonContentType);
      expect(request.data, {
        'device_token': 'test-device-token',
        'refresh_token': 'test-refresh-token',
      });
      expect(await storage.read(key: 'access_token'), isNull);
      expect(await storage.read(key: 'refresh_token'), isNull);
      expect(await storage.read(key: 'user_info_key'), isNull);
      expect(await storage.read(key: 'pending_logouts'), isNull);
      final destination = BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: LoginCard())),
        ),
      );
      await tester.pumpWidget(destination);
      expect(find.text('Device token is invalid.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(destination);
      expect(find.text('Device token is invalid.'), findsOneWidget);
      expect(received, hasLength(1));
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      unawaited(bloc.close());
    }
  });

  for (final onlineAtStartup in [true, false]) {
    test(
      'AuthBloc retries queued logout ${onlineAtStartup ? 'on startup' : 'on reconnect'}',
      () async {
        final changes = StreamController<List<ConnectivityResult>>();
        addTearDown(changes.close);
        final network = LogoutTestNetworkInfo(
          online: false,
          changes: changes.stream,
        );
        var requests = 0;
        final received = Completer<void>();
        final client = contractClient((options) async {
          requests++;
          expect(options.path, '/Auth/logout');
          received.complete();
          return reply(options, {'message': 'Logout confirmed.'});
        });
        addTearDown(client.dio.close);
        await logoutRepository(client, network).logoutUser();
        final repository = logoutRepository(client, network);
        network.online = onlineAtStartup;
        final connectivity = ConnectivityCubit(network);
        addTearDown(connectivity.close);
        final bloc = AuthBloc(
          connectivityCubit: connectivity,
          checkAuthStatusUseCase: CheckAuthStatusUseCase(repository),
          loginUserUseCase: LoginUserUseCase(repository),
          verifyLoginUseCase: VerifyLoginUseCase(repository),
          logoutUserUseCase: LogoutUserUseCase(repository),
          mandatoryChangePasswordUseCase: MandatoryChangePasswordUseCase(
            repository,
          ),
          refreshTokensUseCase: RefreshTokensUseCase(repository),
          registerDeviceTokenUseCase: RegisterDeviceTokenUseCase(repository),
          syncPendingLogoutsUseCase: SyncPendingLogoutsUseCase(repository),
        );
        addTearDown(bloc.close);
        if (!onlineAtStartup) {
          await bloc.stream.firstWhere((state) => state is Unauthenticated);
          expect(requests, 0);
          network.online = true;
          changes.add([ConnectivityResult.wifi]);
        }
        await received.future.timeout(const Duration(seconds: 3));
        await repository.syncPendingLogouts();
        expect(requests, 1);
        expect(await storage.read(key: 'pending_logouts'), isNull);
        expect(await storage.read(key: 'refresh_token'), isNull);
      },
    );
  }

  test(
    'expired access token: notify without bearer, then clear session',
    () async {
      final client = contractClient((options) async {
        expect(options.method, 'POST');
        expect(options.uri.path, '/api/Auth/logout');
        expect(options.headers.containsKey('Authorization'), isFalse);
        expect(options.extra['skipAuth'], isTrue);
        expect(options.contentType, Headers.jsonContentType);
        expect(options.data, {
          'device_token': 'test-device-token',
          'refresh_token': 'test-refresh-token',
        });
        expect(await storage.read(key: 'refresh_token'), 'test-refresh-token');
        return reply(options, {'message': 'Logout confirmed.'});
      });
      addTearDown(client.dio.close);
      expect(
        await logoutRepository(client, LogoutTestNetworkInfo()).logoutUser(),
        isA<Success>(),
      );
      expect(await storage.read(key: 'access_token'), isNull);
      expect(await storage.read(key: 'refresh_token'), isNull);
      expect(await storage.read(key: 'user_info_key'), isNull);
      expect(await storage.read(key: 'pending_logouts'), isNull);
    },
  );

  test(
    'offline logout survives cleanup and restart, then syncs once',
    () async {
      var requests = 0;
      final client = contractClient((options) async {
        requests++;
        expect(options.data, {
          'device_token': 'test-device-token',
          'refresh_token': 'test-refresh-token',
        });
        expect(options.headers.containsKey('Authorization'), isFalse);
        return reply(options, {'message': 'Logout confirmed.'});
      });
      addTearDown(client.dio.close);
      final network = LogoutTestNetworkInfo(online: false);
      expect(
        await logoutRepository(client, network).logoutUser(),
        isA<Success>(),
      );
      expect(requests, 0);
      expect(await storage.read(key: 'pending_logouts'), isNotNull);
      expect(await storage.read(key: 'access_token'), isNull);
      expect(await storage.read(key: 'refresh_token'), isNull);
      network.online = true;
      final restarted = logoutRepository(client, network);
      expect(await restarted.syncPendingLogouts(), isA<Success>());
      await restarted.syncPendingLogouts();
      expect(requests, 1);
      expect(await storage.read(key: 'pending_logouts'), isNull);
    },
  );

  for (final refreshToken in <String?>[null, '']) {
    test('unavailable refresh token is omitted ($refreshToken)', () async {
      final stored = {...session};
      if (refreshToken == null) {
        stored.remove('refresh_token');
      } else {
        stored['refresh_token'] = refreshToken;
      }
      FlutterSecureStorage.setMockInitialValues(stored);
      final client = contractClient((options) async {
        expect(options.data, {'device_token': 'test-device-token'});
        return reply(options, {'message': 'Logout confirmed.'});
      });
      addTearDown(client.dio.close);
      expect(
        await logoutRepository(client, LogoutTestNetworkInfo()).logoutUser(),
        isA<Success>(),
      );
    });
  }

  test('multiple offline sessions retain their own refresh tokens', () async {
    final refreshTokens = <String>[];
    final client = contractClient((options) async {
      final payload = options.data as Map<String, Object?>;
      refreshTokens.add(payload['refresh_token'] as String);
      return reply(options, {'message': 'Logout confirmed.'});
    });
    addTearDown(client.dio.close);
    final network = LogoutTestNetworkInfo(online: false);
    final repository = logoutRepository(client, network);
    await repository.logoutUser();
    await storage.write(key: 'access_token', value: 'another-access');
    await storage.write(key: 'refresh_token', value: 'another-refresh');
    await repository.logoutUser();
    network.online = true;
    await repository.syncPendingLogouts();
    expect(refreshTokens, ['test-refresh-token', 'another-refresh']);
    expect(await storage.read(key: 'pending_logouts'), isNull);
  });

  for (final status in [400, 500]) {
    test(
      '$status preserves service feedback; retry only server failures',
      () async {
        final client = contractClient(
          (options) async => throw DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response<Object?>(
              requestOptions: options,
              statusCode: status,
              data: {
                if (status == 400)
                  'errors': {
                    'device_token': ['Device token is invalid.'],
                  },
                if (status == 500)
                  'message': 'An unexpected server error occurred.',
              },
            ),
          ),
        );
        addTearDown(client.dio.close);
        final result = await logoutRepository(
          client,
          LogoutTestNetworkInfo(),
        ).logoutUser();
        expect(await storage.read(key: 'access_token'), isNull);
        if (status == 400) {
          final failure = (result as ResultFailure).failure;
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, 'Device token is invalid.');
          expect(await storage.read(key: 'pending_logouts'), isNull);
        } else {
          expect(result, isA<Success>());
          expect(await storage.read(key: 'pending_logouts'), isNotNull);
        }
      },
    );
  }

  test(
    'network failure retains the request and concurrent logout is coalesced',
    () async {
      var requests = 0;
      final gate = Completer<void>();
      final started = Completer<void>();
      final client = contractClient((options) async {
        requests++;
        started.complete();
        await gate.future;
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      });
      addTearDown(client.dio.close);
      final repository = logoutRepository(client, LogoutTestNetworkInfo());
      final first = repository.logoutUser();
      final second = repository.logoutUser();
      await started.future;
      gate.complete();
      expect(await first, isA<Success>());
      expect(await second, isA<Success>());
      expect(requests, 1);
      expect(await storage.read(key: 'pending_logouts'), isNotNull);
    },
  );

  for (final invalid in [
    {'device_token': ''},
    {'device_token': 'a' * 501},
    {'device_token': 'device token'},
    {'refresh_token': 'a' * 89},
    {'refresh_token': 'refresh\ttoken'},
  ]) {
    test('rejects invalid logout fields before sending', () async {
      FlutterSecureStorage.setMockInitialValues({...session, ...invalid});
      var requests = 0;
      final client = contractClient((options) async {
        requests++;
        return reply(options, {'message': 'Logout confirmed.'});
      });
      addTearDown(client.dio.close);
      final result = await logoutRepository(
        client,
        LogoutTestNetworkInfo(),
      ).logoutUser();
      expect((result as ResultFailure).failure, isA<ValidationFailure>());
      expect(requests, 0);
      expect(await storage.read(key: 'access_token'), isNull);
      expect(await storage.read(key: 'pending_logouts'), isNull);
    });
  }

  test(
    'pending logout blocks a later device registration until confirmed',
    () async {
      var requests = 0;
      final client = contractClient((options) async {
        requests++;
        expect(options.path, '/Auth/logout');
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response<Object?>(
            requestOptions: options,
            statusCode: 500,
            data: {'message': 'An unexpected server error occurred.'},
          ),
        );
      });
      addTearDown(client.dio.close);
      final network = LogoutTestNetworkInfo(online: false);
      final repository = logoutRepository(client, network);
      await repository.logoutUser();
      await storage.write(key: 'access_token', value: 'new-access');
      await storage.write(key: 'refresh_token', value: 'new-refresh');
      await storage.write(
        key: 'refresh_expiration',
        value: '2099-01-01T00:00:00Z',
      );
      network.online = true;
      final result = await repository.registerDeviceToken();
      expect(
        (result as ResultFailure).failure.message,
        'An unexpected server error occurred.',
      );
      expect(requests, 1);
      expect(await storage.read(key: 'pending_logouts'), isNotNull);
      expect(await storage.read(key: 'refresh_token'), 'new-refresh');
    },
  );
}
