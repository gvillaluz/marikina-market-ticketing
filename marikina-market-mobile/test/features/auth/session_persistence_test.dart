import 'dart:convert';
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/errors/failure.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/network/client.dart';
import 'package:marikina_market_mobile/core/connectivity/cubit/connectivity_cubit.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/refresh_tokens_use_case.dart';
import 'package:marikina_market_mobile/features/auth/data/models/user_model.dart';
import 'package:marikina_market_mobile/features/auth/domain/entities/user.dart';

import 'data/login_mobile_contract_test.dart'
    show contractClient, contractRepository, profileResponse, reply;
import 'login_mobile_flow_test.dart' show loginBloc;
import 'login_test_network_info.dart';

const storage = FlutterSecureStorage();

Future<void> seedSession({bool expiredRefresh = false}) async {
  final payload = base64Url
      .encode(utf8.encode('{"exp":1}'))
      .replaceAll('=', '');
  FlutterSecureStorage.setMockInitialValues({
    'access_token': 'eyJhbGciOiJIUzI1NiJ9.$payload.signature',
    'refresh_token': 'synthetic-refresh-token',
    'refresh_expiration': expiredRefresh
        ? '2000-01-01T00:00:00Z'
        : '2099-01-01T00:00:00Z',
    'user_info_key': jsonEncode(UserModel.fromJson(profileResponse).toJson()),
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final status in <int?>[null, 503]) {
    test(
      'restart preserves cached session when refresh fails with $status',
      () async {
        await seedSession();
        final client = contractClient((options) async {
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
                  ),
          );
        });
        addTearDown(client.dio.close);
        final repository = contractRepository(client);
        expect(await repository.checkAuth(), isA<Success<User?>>());
        expect(
          await storage.read(key: 'refresh_token'),
          'synthetic-refresh-token',
        );
        // A new repository simulates reopening without in-memory session state.
        expect(
          await contractRepository(client).checkAuth(),
          isA<Success<User?>>(),
        );
      },
    );
  }

  test('expired refresh token cannot restore or renew a session', () async {
    await seedSession(expiredRefresh: true);
    var calls = 0;
    final client = contractClient((options) async {
      calls++;
      return reply(options, {});
    });
    addTearDown(client.dio.close);
    final repository = contractRepository(client);
    expect((await repository.checkAuth() as Success<User?>).data, isNull);
    await seedSession(expiredRefresh: true);
    final result = await repository.refreshTokens();
    expect(result, isA<ResultFailure>());
    expect((result as ResultFailure).failure, isA<UnauthorizedFailure>());
    expect(calls, 0);
  });

  test('server rejection never restores cached identity', () async {
    await seedSession();
    final client = contractClient((options) async {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response<Object?>(
          requestOptions: options,
          statusCode: 401,
          data: {'message': 'Session expired.'},
        ),
      );
    });
    addTearDown(client.dio.close);
    final result = await contractRepository(client).checkAuth();
    expect(result, isA<ResultFailure>());
    expect((result as ResultFailure).failure, isA<UnauthorizedFailure>());
    expect(await storage.read(key: 'refresh_token'), isNull);
  });

  for (final status in <int?>[null, 503, 401]) {
    test(
      'request refresh with $status only signs out on definitive rejection',
      () async {
        await seedSession();
        var authFailures = 0;
        var refreshCalls = 0;
        late ApiClient client;
        client = contractClient(
          (options) async {
            if (options.path == '/auth/refresh') refreshCalls++;
            final responseStatus = options.path == '/auth/refresh'
                ? status
                : 401;
            throw DioException(
              requestOptions: options,
              type: responseStatus == null
                  ? DioExceptionType.connectionError
                  : DioExceptionType.badResponse,
              response: responseStatus == null
                  ? null
                  : Response<Object?>(
                      requestOptions: options,
                      statusCode: responseStatus,
                      data: {'message': 'Request failed.'},
                    ),
            );
          },
          refreshAction: () => contractRepository(client).refreshTokens(),
          onAuthFailure: () async {
            authFailures++;
          },
        );
        addTearDown(client.dio.close);
        final result = await contractRepository(client).remoteDataSource
            .getUser()
            .then<Object?>((value) => value, onError: (Object error) => error);
        expect(result, isNot(isA<UserModel>()));
        expect(refreshCalls, 1);
        expect(authFailures, status == 401 ? 1 : 0);
        expect(
          await storage.read(key: 'refresh_token'),
          status == 401 ? isNull : 'synthetic-refresh-token',
        );
      },
    );
  }

  test(
    'waiting protected requests preserve session on shared refresh failure',
    () async {
      await seedSession();
      final pending = Completer<void>();
      final started = Completer<void>();
      var failures = 0;
      late ApiClient client;
      late RefreshTokensUseCase refresh;
      client = contractClient(
        (options) async {
          expect(options.path, '/auth/refresh');
          started.complete();
          await pending.future;
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          );
        },
        refreshAction: () => refresh(),
        waitForRefresh: () => refresh.waitForOngoingRefresh(),
        onAuthFailure: () async {
          failures++;
        },
      );
      addTearDown(client.dio.close);
      refresh = RefreshTokensUseCase(contractRepository(client));
      final renewal = refresh();
      await started.future;
      final requests = List.generate(
        2,
        (_) => client
            .get('/user')
            .then<Object?>((value) => value, onError: (Object error) => error),
      );
      pending.complete();
      expect(await renewal, isA<ResultFailure>());
      for (final error in await Future.wait(requests)) {
        expect(error, isA<DioException>());
        expect((error as DioException).type, DioExceptionType.connectionError);
        expect(error.response, isNull);
      }
      expect(failures, 0);
      expect(
        await storage.read(key: 'refresh_token'),
        'synthetic-refresh-token',
      );
    },
  );

  test('recovery saves rotated tokens and restores a fresh repository', () async {
    await seedSession();
    final client = contractClient(
      (options) async => reply(options, {
        'access_token':
            'eyJhbGciOiJIUzI1NiJ9.${base64Url.encode(utf8.encode('{"exp":4070908800}')).replaceAll('=', '')}.signature',
        'refresh_token': 'synthetic-rotated-refresh',
        'refresh_token_expiration': '2099-02-01T00:00:00Z',
      }),
    );
    addTearDown(client.dio.close);
    expect(await contractRepository(client).checkAuth(), isA<Success<User?>>());
    expect(
      await storage.read(key: 'refresh_token'),
      'synthetic-rotated-refresh',
    );
    expect(
      DateTime.parse((await storage.read(key: 'refresh_expiration'))!),
      DateTime.utc(2099, 2),
    );
    expect(await contractRepository(client).checkAuth(), isA<Success<User?>>());
  });

  for (final status in <int?>[null, 503, 401]) {
    test(
      'background refresh with $status preserves identity unless rejected',
      () async {
        await seedSession();
        var reject = false;
        final connectivity = ConnectivityCubit(LoginTestNetworkInfo());
        final bloc = loginBloc(connectivity, (options) async {
          if (!reject) {
            return reply(options, {
              'access_token':
                  'eyJhbGciOiJIUzI1NiJ9.${base64Url.encode(utf8.encode('{"exp":4070908800}')).replaceAll('=', '')}.signature',
              'refresh_token': 'synthetic-renewed',
              'refresh_token_expiration': '2099-02-01T00:00:00Z',
            });
          }
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
                    data: {'message': 'Refresh failed.'},
                  ),
          );
        });
        addTearDown(bloc.close);
        addTearDown(connectivity.close);
        await bloc.stream.firstWhere((state) => state is Authenticated);
        reject = true;
        bloc.add(RefreshTokens());
        await Future<void>.delayed(Duration.zero);
        await bloc.refreshTokensUseCase.waitForOngoingRefresh();
        await Future<void>.delayed(Duration.zero);
        expect(
          bloc.state,
          status == 401 ? isA<Unauthenticated>() : isA<Authenticated>(),
        );
        expect(
          await storage.read(key: 'refresh_token'),
          status == 401 ? isNull : 'synthetic-renewed',
        );
      },
    );
  }
}
