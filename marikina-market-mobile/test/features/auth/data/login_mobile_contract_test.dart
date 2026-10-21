import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/errors/failure.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/network/client.dart';
import 'package:marikina_market_mobile/core/utils/unit.dart';
import 'package:marikina_market_mobile/core/storage/secure_storage_service_impl.dart';
import 'package:marikina_market_mobile/features/auth/data/data_sources/auth_local_data_source.dart';
import 'package:marikina_market_mobile/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:marikina_market_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:marikina_market_mobile/features/auth/domain/entities/login_otp_result.dart';
import 'package:marikina_market_mobile/features/auth/domain/entities/user.dart';
import 'package:marikina_market_mobile/features/auth/domain/enums/role.dart';
import 'package:marikina_market_mobile/features/auth/domain/services/token_service_impl.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/verify_login_params.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/verify_login_use_case.dart';
import '../logout_test_network_info.dart';

const otpResponse = <String, Object?>{
  'message': 'Code sent.',
  'masked_email': 'e***@example.com',
  'resend_cooldown_seconds': 30,
  'code_expiry_seconds': 600,
};
const tokenResponse = <String, Object?>{
  'access_token': 'test-access-token',
  'refresh_token': 'test-refresh-token',
  'refresh_token_expiration': '2026-12-11T05:00:00Z',
};
// Matches the local API's UserProfileResponse contract; no personal records.
const profileResponse = <String, Object?>{
  'userId': 1,
  'username': 'enforcer01',
  'firstName': 'Test',
  'middleName': null,
  'lastName': 'Enforcer',
  'email': 'enforcer@example.com',
  'dateOfBirth': '2000-01-01',
  'phoneNumber': '0000000000',
  'houseNumber': '1',
  'street': 'Test',
  'barangay': 'Test',
  'city': 'Marikina',
  'status': 'Active',
  'role': 'MarketEnforcer',
  'createdAt': '2026-01-01T00:00:00Z',
  'profileUrl': null,
  'mustChangedPassword': false,
};

ApiClient contractClient(
  Future<Response<Object?>> Function(RequestOptions) respond, {
  Future<Result<Unit>> Function()? refreshAction,
  Future<Result<Unit>> Function()? waitForRefresh,
  Future<void> Function()? onAuthFailure,
}) {
  final client = ApiClient(
    refreshAction: refreshAction,
    waitForRefresh: waitForRefresh,
    onAuthFailure: onAuthFailure,
  );
  client.dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          handler.resolve(await respond(options));
        } on DioException catch (error) {
          handler.reject(error, true);
        }
      },
    ),
  );
  return client;
}

Response<Object?> reply(RequestOptions options, Object? data) =>
    Response<Object?>(requestOptions: options, statusCode: 200, data: data);

AuthRepositoryImpl contractRepository(ApiClient client) => AuthRepositoryImpl(
  remoteDataSource: AuthRemoteDataSourceImpl(apiClient: client),
  localDataSource: AuthLocalDataSourceImpl(
    storageService: const SecureStorageServiceImpl(
      storage: FlutterSecureStorage(),
    ),
  ),
  tokenService: TokenServiceImpl(),
  networkInfo: LogoutTestNetworkInfo(),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'credential submission accepts OTP response and removes stale auth',
    () async {
      final client = contractClient((options) async {
        expect(options.path, '/auth/login-mobile');
        expect(options.extra['skipAuth'], isTrue);
        expect(options.headers.containsKey('Authorization'), isFalse);
        expect(options.data, {
          'username': 'enforcer01',
          'password': 'ExamplePass123',
        });
        return reply(options, otpResponse);
      });
      client.dio.options.headers['Authorization'] = 'Bearer stale-token';
      final result = await AuthRemoteDataSourceImpl(
        apiClient: client,
      ).login('enforcer01', 'ExamplePass123');
      expect(result.maskedEmail, 'e***@example.com');
      expect(result.resendCooldownSeconds, 30);
      expect(result.codeExpirySeconds, 600);
      client.dio.close();
    },
  );

  test(
    'login stores nothing until OTP verification and then uses Bearer token',
    () async {
      final requests = <String>[];
      final client = contractClient((options) async {
        requests.add(options.path);
        if (options.path == '/auth/login-mobile') {
          return reply(options, otpResponse);
        }
        if (options.path == '/auth/verify-login-mobile') {
          expect(options.extra['skipAuth'], isTrue);
          expect(options.headers.containsKey('Authorization'), isFalse);
          expect(options.data, {
            'username': 'enforcer01',
            'password': ' ExamplePass123 ',
            'code': '001234',
          });
          return reply(options, tokenResponse);
        }
        expect(options.path, '/user/me');
        expect(options.headers['Authorization'], 'Bearer test-access-token');
        return reply(options, profileResponse);
      });
      final repository = contractRepository(client);
      final sent = await repository.loginUser('enforcer01', ' ExamplePass123 ');
      expect(sent, isA<Success<LoginOtpResult>>());
      expect(await const FlutterSecureStorage().readAll(), isEmpty);
      expect(requests, ['/auth/login-mobile']);
      final verified = await repository.verifyLogin(
        'enforcer01',
        ' ExamplePass123 ',
        '001234',
      );
      expect(verified, isA<Success<User>>());
      expect((verified as Success<User>).data.role, Role.marketEnforcer);
      final stored = await const FlutterSecureStorage().readAll();
      expect(stored['access_token'], 'test-access-token');
      expect(stored['refresh_token'], 'test-refresh-token');
      expect(
        DateTime.parse(stored['refresh_expiration']!),
        DateTime.utc(2026, 12, 11, 5),
      );
      expect(stored.containsKey('user_info_key'), isTrue);
      expect(
        stored.values.any((value) => value.contains('ExamplePass123')),
        isFalse,
      );
      client.dio.close();
    },
  );

  test(
    'resend keeps server remaining countdowns for an already sent code',
    () async {
      final client = contractClient(
        (options) async => reply(options, {
          ...otpResponse,
          'message': 'Code already sent.',
          'resend_cooldown_seconds': 12,
          'code_expiry_seconds': 582,
        }),
      );
      final result = await contractRepository(
        client,
      ).loginUser('enforcer01', 'ExamplePass123');
      final otp = (result as Success<LoginOtpResult>).data;
      expect(otp.message, 'Code already sent.');
      expect(otp.resendCooldownSeconds, 12);
      expect(otp.codeExpirySeconds, 582);
      client.dio.close();
    },
  );

  for (final entry in <int, List<String>>{
    400: [
      'Invalid username or password.',
      'No valid email. Contact an admin.',
      'Incorrect code. Try again.',
      'Code expired. Request a new one.',
      'Too many attempts. Request a new code.',
      'Invalid or expired code.',
    ],
    403: ['Account is inactive.', 'Account cannot use this application.'],
    423: ['Too many attempts. Please try again later.'],
  }.entries) {
    for (final message in entry.value) {
      test('${entry.key} preserves "$message" and stores no tokens', () async {
        final client = contractClient(
          (options) async => throw DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response<Object?>(
              requestOptions: options,
              statusCode: entry.key,
              data: {'message': message},
            ),
          ),
        );
        final repository = contractRepository(client);
        final sent = await repository.loginUser('enforcer01', 'ExamplePass123');
        final verified = await repository.verifyLogin(
          'enforcer01',
          'ExamplePass123',
          '001234',
        );
        expect((sent as ResultFailure).failure.message, message);
        expect((verified as ResultFailure).failure.message, message);
        expect(await const FlutterSecureStorage().readAll(), isEmpty);
        client.dio.close();
      });
    }
  }

  test('ASP.NET field validation messages become domain failures', () async {
    final client = contractClient(
      (options) async => throw DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response<Object?>(
          requestOptions: options,
          statusCode: 400,
          data: {
            'errors': {
              'Code': ['The Code field is required.'],
            },
          },
        ),
      ),
    );
    final result = await contractRepository(
      client,
    ).verifyLogin('enforcer01', 'ExamplePass123', '001234');
    expect(
      (result as ResultFailure).failure.message,
      'The Code field is required.',
    );
    client.dio.close();
  });

  test('invalid OTP input does not call the server', () async {
    var requests = 0;
    final client = contractClient((options) async {
      requests++;
      return reply(options, tokenResponse);
    });
    final verify = VerifyLoginUseCase(contractRepository(client));
    for (final code in ['12345', '1234567', '12a456', ' 123456']) {
      final result = await verify(
        VerifyLoginParams(
          username: 'enforcer01',
          password: 'ExamplePass123',
          code: code,
        ),
      );
      expect((result as ResultFailure).failure, isA<ValidationFailure>());
    }
    expect(requests, 0);
    client.dio.close();
  });

  test('refresh persists rotated tokens and expiration', () async {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'old-access',
      'refresh_token': 'old-refresh',
      'refresh_expiration': '2026-12-01T00:00:00Z',
    });
    final client = contractClient((options) async {
      expect(options.path, '/auth/refresh');
      expect(options.data, {'refresh_token': 'old-refresh'});
      expect(options.headers.containsKey('Authorization'), isFalse);
      return reply(options, tokenResponse);
    });
    expect(await contractRepository(client).refreshTokens(), isA<Success>());
    final stored = await const FlutterSecureStorage().readAll();
    expect(stored['access_token'], 'test-access-token');
    expect(stored['refresh_token'], 'test-refresh-token');
    expect(
      DateTime.parse(stored['refresh_expiration']!),
      DateTime.utc(2026, 12, 11, 5),
    );
    client.dio.close();
  });

  test('profile failure after verification clears partial session', () async {
    final client = contractClient((options) async {
      if (options.path == '/auth/verify-login-mobile') {
        return reply(options, tokenResponse);
      }
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    });
    final result = await contractRepository(
      client,
    ).verifyLogin('enforcer01', 'ExamplePass123', '001234');
    expect((result as ResultFailure).failure, isA<NetworkFailure>());
    expect(await const FlutterSecureStorage().readAll(), isEmpty);
    client.dio.close();
  });

  test('public login failures never invoke session refresh', () async {
    var refreshes = 0;
    final client = contractClient(
      (options) async => throw DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response<Object?>(requestOptions: options, statusCode: 401),
      ),
      refreshAction: () async {
        refreshes++;
        return Result.failure(const UnauthorizedFailure('Session expired.'));
      },
    );
    await contractRepository(client).loginUser('enforcer01', 'ExamplePass123');
    expect(refreshes, 0);
    client.dio.close();
  });
}
