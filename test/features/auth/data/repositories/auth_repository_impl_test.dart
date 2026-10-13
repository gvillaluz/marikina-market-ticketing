import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/errors/exceptions.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/account_status.dart';
import 'package:marikina_market_mobile/features/auth/data/data_sources/auth_local_data_source.dart';
import 'package:marikina_market_mobile/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:marikina_market_mobile/features/auth/data/models/auth_tokens.dart';
import 'package:marikina_market_mobile/features/auth/data/models/login_otp_result_model.dart';
import 'package:marikina_market_mobile/features/auth/data/models/logout_request_model.dart';
import '../../logout_test_network_info.dart';
import 'package:marikina_market_mobile/features/auth/data/models/user_model.dart';
import 'package:marikina_market_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:marikina_market_mobile/features/auth/domain/enums/role.dart';
import 'package:marikina_market_mobile/features/auth/domain/services/token_service.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/refresh_tokens_use_case.dart';

void main() {
  group('AuthRepositoryImpl.checkAuth', () {
    test(
      'refreshes an expired access token before returning the user',
      () async {
        final localDataSource = _FakeAuthLocalDataSource();
        final remoteDataSource = _FakeAuthRemoteDataSource();
        final repository = AuthRepositoryImpl(
          localDataSource: localDataSource,
          remoteDataSource: remoteDataSource,
          tokenService: const _FakeTokenService(),
          networkInfo: LogoutTestNetworkInfo(),
        );

        final result = await repository.checkAuth();

        expect(result, isA<Success>());
        expect(remoteDataSource.refreshCalls, 1);
        expect(localDataSource.userReadWithFreshToken, isTrue);
      },
    );

    test(
      'does not authenticate when refreshing an expired token fails',
      () async {
        final localDataSource = _FakeAuthLocalDataSource();
        final remoteDataSource = _FakeAuthRemoteDataSource()
          ..refreshError = UnauthorizedException('Session expired.');
        final repository = AuthRepositoryImpl(
          localDataSource: localDataSource,
          remoteDataSource: remoteDataSource,
          tokenService: const _FakeTokenService(),
          networkInfo: LogoutTestNetworkInfo(),
        );

        final result = await repository.checkAuth();

        expect(result, isA<ResultFailure>());
        expect(localDataSource.userReadCount, 0);
      },
    );
  });

  test('coalesces concurrent refresh requests', () async {
    final localDataSource = _FakeAuthLocalDataSource();
    final remoteDataSource = _FakeAuthRemoteDataSource()
      ..refreshCompleter = Completer<AuthTokens>();
    final repository = AuthRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
      tokenService: const _FakeTokenService(),
      networkInfo: LogoutTestNetworkInfo(),
    );

    final firstRefresh = repository.refreshTokens();
    final secondRefresh = repository.refreshTokens();

    await Future<void>.delayed(Duration.zero);
    expect(remoteDataSource.refreshCalls, 1);
    remoteDataSource.refreshCompleter!.complete(_freshTokens);
    final results = await Future.wait([firstRefresh, secondRefresh]);

    expect(results, everyElement(isA<Success>()));
    expect(remoteDataSource.refreshCalls, 1);
  });

  test('waits for an automatic refresh already in progress', () async {
    final localDataSource = _FakeAuthLocalDataSource();
    final remoteDataSource = _FakeAuthRemoteDataSource()
      ..refreshCompleter = Completer<AuthTokens>();
    final repository = AuthRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
      tokenService: const _FakeTokenService(),
      networkInfo: LogoutTestNetworkInfo(),
    );
    final refreshUseCase = RefreshTokensUseCase(repository);

    final firstRefresh = refreshUseCase();
    final secondRefresh = refreshUseCase();
    final refreshWaiter = refreshUseCase.waitForOngoingRefresh();

    await Future<void>.delayed(Duration.zero);
    expect(remoteDataSource.refreshCalls, 1);
    remoteDataSource.refreshCompleter!.complete(_freshTokens);

    expect(await refreshWaiter, isTrue);
    expect(await firstRefresh, isA<Success>());
    expect(await secondRefresh, isA<Success>());
    expect(remoteDataSource.refreshCalls, 1);
  });
}

final _expiredTokens = AuthTokens(
  accessToken: 'expired-access-token',
  refreshToken: 'refresh-token',
  refreshTokenExpiration: _futureExpiration,
);

final _freshTokens = AuthTokens(
  accessToken: 'fresh-access-token',
  refreshToken: 'fresh-refresh-token',
  refreshTokenExpiration: _futureExpiration,
);

final _futureExpiration = DateTime.utc(2099);

class _FakeTokenService implements TokenService {
  const _FakeTokenService();

  @override
  Map<String, dynamic>? decodeToken(String? token) => null;

  @override
  bool isAccessTokenExpired(String? token) => token == 'expired-access-token';
}

class _FakeAuthLocalDataSource implements AuthLocalDataSource {
  @override
  Future<LogoutRequestModel?> getLogoutRequest() async => null;
  @override
  Future<List<LogoutRequestModel>> getPendingLogouts() async => [];
  @override
  Future<void> savePendingLogouts(List<LogoutRequestModel> requests) async {}
  @override
  Future<String> getDeviceTokenForRegistration() async => 'test-device-token';
  AuthTokens tokens = _expiredTokens;
  int userReadCount = 0;
  bool userReadWithFreshToken = false;

  @override
  Future<AuthTokens> getTokens() async => tokens;

  @override
  Future<void> storeTokens(AuthTokens tokens) async {
    this.tokens = tokens;
  }

  @override
  Future<UserModel> getUser() async {
    userReadCount++;
    userReadWithFreshToken = tokens.accessToken == _freshTokens.accessToken;
    return UserModel(
      userId: 1,
      username: 'user',
      firstName: 'Test',
      lastName: 'User',
      middleName: null,
      email: 'test@example.com',
      dateOfBirth: DateTime(2000),
      mobileNumber: '0000000000',
      address: 'Market',
      role: Role.marketEnforcer,
      status: AccountStatus.active,
      profileUrl: null,
      createdAt: DateTime(2020),
      mustChangePassword: false,
    );
  }

  @override
  Future<void> removeUser() async {}

  @override
  Future<void> storeUser(UserModel user) async {}
}

class _FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  @override
  Future<void> logout(LogoutRequestModel request) async {}
  int refreshCalls = 0;
  Object? refreshError;
  Completer<AuthTokens>? refreshCompleter;

  @override
  Future<AuthTokens> refreshAuthTokens(String refreshToken) async {
    refreshCalls++;
    if (refreshError case final error?) throw error;
    final completer = refreshCompleter;
    return completer == null ? _freshTokens : completer.future;
  }

  @override
  Future<UserModel> getUser() async => throw UnimplementedError();

  @override
  Future<void> changePassword(
    int userId,
    String currentPassword,
    String newPassword,
    String confirmNewPassword,
  ) async => throw UnimplementedError();

  @override
  Future<LoginOtpResultModel> login(String username, String password) async =>
      throw UnimplementedError();

  @override
  Future<AuthTokens> verifyLogin(
    String username,
    String password,
    String code,
  ) async => throw UnimplementedError();

  @override
  Future<void> registerDeviceToken(String deviceToken) async =>
      throw UnimplementedError();
}
