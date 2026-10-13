import 'package:marikina_market_mobile/core/network/network_info.dart';
import 'package:marikina_market_mobile/features/auth/domain/entities/logout_request.dart';
import 'package:marikina_market_mobile/core/errors/exceptions.dart';
import 'package:marikina_market_mobile/core/errors/failure.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/utils/unit.dart';
import 'package:marikina_market_mobile/features/auth/data/data_sources/auth_local_data_source.dart';
import 'package:marikina_market_mobile/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:marikina_market_mobile/features/auth/data/models/user_model.dart';
import 'package:marikina_market_mobile/features/auth/domain/entities/user.dart';
import 'package:marikina_market_mobile/features/auth/domain/entities/login_otp_result.dart';
import 'package:marikina_market_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:marikina_market_mobile/features/auth/domain/services/token_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final TokenService tokenService;
  final NetworkInfo networkInfo;
  Future<Result<Unit>>? _refreshInFlight;
  Future<Result<Unit>>? _logoutInFlight;
  Future<void> _logoutQueueWork = Future<void>.value();

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.tokenService,
    required this.networkInfo,
  });

  @override
  Future<Result<User?>> checkAuth() async {
    try {
      final authTokens = await localDataSource.getTokens();

      final sessionRecoverable = authTokens.refreshTokenExpiration.isAfter(
        DateTime.now(),
      );
      if (!sessionRecoverable) return Result.success(null);

      if (tokenService.isAccessTokenExpired(authTokens.accessToken)) {
        final refreshResult = await refreshTokens();
        if (refreshResult case ResultFailure(failure: final failure)) {
          return Result.failure(failure);
        }
      }

      final userModel = await localDataSource.getUser();

      return Result.success(userModel.toEntity());
    } on CacheException catch (e) {
      return Result.failure(CacheFailure(e.message));
    }
  }

  @override
  Future<Result<LoginOtpResult>> loginUser(
    String username,
    String password,
  ) async {
    try {
      final result = await remoteDataSource.login(username, password);
      return Result.success(result.toEntity());
    } on UnauthorizedException catch (e) {
      return Result.failure(UnauthorizedFailure(e.message));
    } on NetworkException catch (e) {
      return Result.failure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message));
    }
  }

  @override
  Future<Result<User>> verifyLogin(
    String username,
    String password,
    String code,
  ) async {
    var tokensReceived = false;
    var completed = false;
    try {
      final authLoginTokens = await remoteDataSource.verifyLogin(
        username,
        password,
        code,
      );
      tokensReceived = true;
      await localDataSource.storeTokens(authLoginTokens);

      final user = await remoteDataSource.getUser();
      await localDataSource.storeUser(user);

      completed = true;
      return Result.success(user.toEntity());
    } on UnauthorizedException catch (e) {
      return Result.failure(UnauthorizedFailure(e.message));
    } on CacheException catch (e) {
      return Result.failure(CacheFailure(e.message));
    } on NetworkException catch (e) {
      return Result.failure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } finally {
      if (tokensReceived && !completed) {
        await localDataSource.removeUser();
      }
    }
  }

  @override
  Future<Result<Unit>> storeUserInfo(User user) async {
    try {
      await localDataSource.storeUser(UserModel.fromEntity(user));
      return Result.success(unit);
    } on CacheException catch (e) {
      return Result.failure(CacheFailure(e.message));
    }
  }

  @override
  Future<Result<Unit>> logoutUser() {
    final pending = _logoutInFlight;
    if (pending != null) return pending;
    final logout = _serializeLogoutWork(_performLogout);
    _logoutInFlight = logout;
    return logout.whenComplete(() {
      if (identical(_logoutInFlight, logout)) _logoutInFlight = null;
    });
  }

  Future<Result<Unit>> _serializeLogoutWork(
    Future<Result<Unit>> Function() action,
  ) {
    final work = _logoutQueueWork.then((_) => action());
    _logoutQueueWork = work.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return work;
  }

  Future<Result<Unit>> _performLogout() async {
    try {
      try {
        final refresh = _refreshInFlight;
        if (refresh != null) await refresh;
        final request = await localDataSource.getLogoutRequest();
        if (request == null) {
          return Result.failure(
            const ValidationFailure(
              'Signed out on this device, but no device token was available to notify the server.',
            ),
          );
        }
        final validation = _validateLogoutRequest(request.toEntity());
        if (validation != null) {
          return Result.failure(ValidationFailure(validation));
        }
        final pending = await localDataSource.getPendingLogouts();
        if (!pending.any(
          (item) =>
              item.deviceToken == request.deviceToken &&
              item.refreshToken == request.refreshToken,
        )) {
          pending.add(request);
          await localDataSource.savePendingLogouts(pending);
        }
        return await _drainPendingLogouts();
      } finally {
        await localDataSource.removeUser();
      }
    } on NetworkException {
      // The durable request will retry after reconnecting or restarting.
      return Result.success(unit);
    } on ServerException {
      return Result.success(unit);
    } on ValidationException catch (e) {
      return Result.failure(ValidationFailure(e.message));
    } on CacheException catch (e) {
      return Result.failure(CacheFailure(e.message));
    } catch (_) {
      return Result.failure(
        const ServerFailure('Unable to complete logout. Please try again.'),
      );
    }
  }

  @override
  Future<Result<Unit>> syncPendingLogouts() => _serializeLogoutWork(() async {
    try {
      return await _drainPendingLogouts();
    } on ValidationException catch (e) {
      return Result.failure(ValidationFailure(e.message));
    } on NetworkException catch (e) {
      return Result.failure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Result.failure(CacheFailure(e.message));
    } catch (_) {
      return Result.failure(
        const ServerFailure('Unable to sync pending logout requests.'),
      );
    }
  });

  Future<Result<Unit>> _drainPendingLogouts() async {
    final pending = await localDataSource.getPendingLogouts();
    if (pending.isEmpty) return Result.success(unit);
    if (!await networkInfo.hasInternetAccess) throw NetworkException('');
    while (pending.isNotEmpty) {
      final request = pending.first;
      final validation = _validateLogoutRequest(request.toEntity());
      try {
        if (validation != null) throw ValidationException(validation);
        await remoteDataSource.logout(request);
      } on ValidationException {
        // A rejected payload cannot succeed unchanged; do not retry it forever.
        pending.removeAt(0);
        await localDataSource.savePendingLogouts(pending);
        rethrow;
      }
      pending.removeAt(0);
      await localDataSource.savePendingLogouts(pending);
    }
    return Result.success(unit);
  }

  String? _validateLogoutRequest(LogoutRequest request) {
    final whitespace = RegExp(r'\s');
    if (request.deviceToken.isEmpty ||
        request.deviceToken.length > 500 ||
        whitespace.hasMatch(request.deviceToken)) {
      return 'Unable to notify the server: the device token is invalid.';
    }
    final refreshToken = request.refreshToken;
    if (refreshToken != null &&
        (refreshToken.isEmpty ||
            refreshToken.length > 88 ||
            whitespace.hasMatch(refreshToken))) {
      return 'Unable to notify the server: the refresh token is invalid.';
    }
    return null;
  }

  @override
  Future<Result<User>> mandatoryChangePassword(
    int userId,
    String currentPassword,
    String newPassword,
    String confirmNewPassword,
  ) async {
    try {
      await remoteDataSource.changePassword(
        userId,
        currentPassword,
        newPassword,
        confirmNewPassword,
      );

      final user = await localDataSource.getUser();

      final newUser = UserModel(
        userId: user.userId,
        username: user.username,
        firstName: user.firstName,
        lastName: user.lastName,
        middleName: user.middleName,
        email: user.email,
        dateOfBirth: user.dateOfBirth,
        mobileNumber: user.mobileNumber,
        address: user.address,
        houseNumber: user.houseNumber,
        street: user.street,
        barangay: user.barangay,
        city: user.city,
        role: user.role,
        status: user.status,
        profileUrl: user.profileUrl,
        createdAt: user.createdAt,
        mustChangePassword: false,
      );

      await localDataSource.storeUser(newUser);

      return Result.success(newUser.toEntity());
    } on TokenExpiredException catch (e) {
      return Result.failure(TokenValidationFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Result.failure(UnauthorizedFailure(e.message));
    } on CacheException catch (e) {
      return Result.failure(CacheFailure(e.message));
    } on NetworkException catch (e) {
      return Result.failure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message));
    }
  }

  @override
  Future<Result<Unit>> refreshTokens() {
    if (_logoutInFlight != null) {
      return Future.value(
        Result.failure(const UnauthorizedFailure('Signed out.')),
      );
    }
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;

    final refresh = _performRefreshTokens();
    _refreshInFlight = refresh;
    return refresh.whenComplete(() {
      if (identical(_refreshInFlight, refresh)) {
        _refreshInFlight = null;
      }
    });
  }

  Future<Result<Unit>> _performRefreshTokens() async {
    try {
      final tokens = await localDataSource.getTokens();
      final freshTokens = await remoteDataSource.refreshAuthTokens(
        tokens.refreshToken,
      );
      await localDataSource.storeTokens(freshTokens);

      return Result.success(unit);
    } on CacheException catch (e) {
      return Result.failure(UnauthorizedFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Result.failure(UnauthorizedFailure(e.message));
    } on NetworkException catch (e) {
      return Result.failure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message));
    }
  }

  @override
  Future<Result<Unit>> registerDeviceToken() =>
      _serializeLogoutWork(_registerDeviceToken);

  Future<Result<Unit>> _registerDeviceToken() async {
    try {
      await _drainPendingLogouts();
      // A registration queued before logout must not recreate a removed binding.
      await localDataSource.getTokens();
      final token = await localDataSource.getDeviceTokenForRegistration();
      final validation = _validateLogoutRequest(
        LogoutRequest(deviceToken: token),
      );
      if (validation != null) {
        return Result.failure(ValidationFailure(validation));
      }
      await remoteDataSource.registerDeviceToken(token);
      return Result.success(unit);
    } on ValidationException catch (e) {
      return Result.failure(ValidationFailure(e.message));
    } on CacheException catch (e) {
      return Result.failure(CacheFailure(e.message));
    } on NetworkException catch (e) {
      return Result.failure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure("Failed to register device token."));
    }
  }
}
