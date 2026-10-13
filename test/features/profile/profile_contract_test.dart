import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/errors/failure.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/network/client.dart';
import 'package:marikina_market_mobile/features/auth/domain/entities/user.dart';
import 'package:marikina_market_mobile/features/profile/data/data_sources/profile_remote_data_source.dart';
import 'package:marikina_market_mobile/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:marikina_market_mobile/features/profile/domain/use_cases/edit_profile_params.dart';
import 'package:marikina_market_mobile/features/profile/domain/use_cases/edit_profile_use_case.dart';
import '../auth/data/login_mobile_contract_test.dart'
    show contractClient, contractRepository, reply;
import 'package:marikina_market_mobile/features/auth/data/models/user_model.dart';

const profileResponse = <String, Object?>{
  'userId': 7,
  'username': 'enforcer01',
  'firstName': 'Juan',
  'middleName': 'Santos',
  'lastName': 'Dela Cruz',
  'email': 'juan@example.com',
  'dateOfBirth': '1995-06-15',
  'phoneNumber': '09171234567',
  'houseNumber': '123',
  'street': 'J.P. Rizal',
  'barangay': 'Sta. Elena',
  'city': 'Marikina',
  'status': 'Active',
  'role': 'MarketEnforcer',
  'createdAt': '2026-10-01T08:00:00Z',
  'profileUrl': null,
  'mustChangedPassword': false,
};

EditProfileParams profileParams({
  String firstName = 'Juan',
  String? middleName = 'Santos',
  String lastName = 'Dela Cruz',
  DateTime? dateOfBirth,
  String email = 'juan@example.com',
  String phoneNumber = '09171234567',
  String houseNumber = '123',
  String street = 'J.P. Rizal',
  String barangay = 'Sta. Elena',
  String city = 'Marikina',
}) => EditProfileParams(
  firstName: firstName,
  middleName: middleName,
  lastName: lastName,
  dateOfBirth: dateOfBirth ?? DateTime(1995, 6, 15),
  email: email,
  phoneNumber: phoneNumber,
  houseNumber: houseNumber,
  street: street,
  barangay: barangay,
  city: city,
);

ProfileRepositoryImpl profileRepository(ApiClient client) =>
    ProfileRepositoryImpl(
      ProfileRemoteDataSourceImpl(client),
      contractRepository(client),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => FlutterSecureStorage.setMockInitialValues({
      'access_token': 'test-access-token',
    }),
  );
  test('structured address survives entity and secure-cache mapping', () {
    final model = UserModel.fromJson(profileResponse);
    final cached = UserModel.fromEntity(model.toEntity()).toJson();
    expect(cached['house_number'], '123');
    expect(cached['street'], 'J.P. Rizal');
    expect(cached['barangay'], 'Sta. Elena');
    expect(cached['city'], 'Marikina');
    expect(UserModel.fromJson(cached).toJson(), cached);
  });
  test(
    'POST uses all snake_case fields, JWT identity, and exact camelCase response',
    () async {
      final client = contractClient((options) async {
        expect(options.method, 'POST');
        expect(options.uri.path, '/api/User/profile');
        expect(options.headers['Authorization'], 'Bearer test-access-token');
        expect(options.contentType, Headers.jsonContentType);
        expect(options.data, {
          'first_name': 'Juan',
          'middle_name': 'Santos',
          'last_name': 'Dela Cruz',
          'date_of_birth': '1995-06-15',
          'email': 'juan@example.com',
          'phone_number': '09171234567',
          'house_number': '123',
          'street': 'J.P. Rizal',
          'barangay': 'Sta. Elena',
          'city': 'Marikina',
        });
        return reply(options, {
          ...profileResponse,
          'mustChangedPassword': true,
        });
      });
      addTearDown(client.dio.close);
      final result = await EditProfileUseCase(profileRepository(client))(
        profileParams(),
      );
      final user = (result as Success<User>).data;
      expect(user.userId, 7);
      expect(user.mustChangePassword, isTrue);
      expect(user.houseNumber, '123');
      final stored = await contractRepository(client).localDataSource.getUser();
      expect(stored.toEntity().houseNumber, '123');
      expect(stored.city, 'Marikina');
      expect(stored.email, 'juan@example.com');
    },
  );

  for (final entry in {
    'HeadAdmin': 'HeadAdmin',
    'AdminOfficer': 'AdminOfficer',
    'MarketEnforcer': 'MarketEnforcer',
    'MarketVendor': 'MarketVendor',
  }.entries) {
    test(
      'profile update maps ${entry.key} and retains the image URL',
      () async {
        const photoUrl = 'https://example.com/profile.jpg?signature=test';
        final client = contractClient(
          (options) async => reply(options, {
            ...profileResponse,
            'role': entry.key,
            'profileUrl': photoUrl,
          }),
        );
        addTearDown(client.dio.close);
        final result = await EditProfileUseCase(profileRepository(client))(
          profileParams(),
        );
        expect(result, isA<Success<User>>());
        final user = (result as Success<User>).data;
        expect(user.role.value, entry.value);
        expect(user.profileUrl, photoUrl);
        final stored = await contractRepository(
          client,
        ).localDataSource.getUser();
        expect(stored.toEntity().role, user.role);
      },
    );
  }

  test('trim profile fields and send an empty middle name as null', () async {
    final client = contractClient((options) async {
      final payload = options.data as Map<String, Object?>;
      expect(payload['first_name'], 'Juan');
      expect(payload['middle_name'], isNull);
      expect(payload['street'], 'J.P. Rizal');
      return reply(options, {...profileResponse, 'middleName': null});
    });
    addTearDown(client.dio.close);
    final result = await EditProfileUseCase(profileRepository(client))(
      profileParams(
        firstName: ' Juan ',
        middleName: '   ',
        street: ' J.P. Rizal ',
      ),
    );
    expect((result as Success<User>).data.middleName, isNull);
  });

  test(
    'reject missing fields, invalid phone/email, and future birth date before HTTP',
    () async {
      var requests = 0;
      final client = contractClient((options) async {
        requests++;
        return reply(options, profileResponse);
      });
      addTearDown(client.dio.close);
      final edit = EditProfileUseCase(profileRepository(client));
      final invalid = [
        profileParams(firstName: ' '),
        profileParams(lastName: ''),
        profileParams(email: ''),
        profileParams(email: 'invalid'),
        profileParams(phoneNumber: '0917123456'),
        profileParams(phoneNumber: '08171234567'),
        profileParams(phoneNumber: '0917123456a'),
        profileParams(houseNumber: ''),
        profileParams(street: ' '),
        profileParams(barangay: ''),
        profileParams(city: ''),
        profileParams(dateOfBirth: DateTime.now().add(const Duration(days: 1))),
        profileParams(firstName: 'a' * 101),
        profileParams(middleName: 'a' * 101),
        profileParams(lastName: 'a' * 101),
        profileParams(email: '${'a' * 244}@example.com'),
        profileParams(houseNumber: 'a' * 51),
        profileParams(street: 'a' * 101),
        profileParams(barangay: 'a' * 101),
        profileParams(city: 'a' * 101),
      ];
      for (final params in invalid) {
        final result = await edit(params);
        expect((result as ResultFailure).failure, isA<ValidationFailure>());
      }
      expect(requests, 0);
    },
  );

  test('today is a valid date of birth and preserves calendar date', () async {
    final today = DateTime.now();
    final client = contractClient((options) async {
      expect(
        (options.data as Map)['date_of_birth'],
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}',
      );
      return reply(options, profileResponse);
    });
    addTearDown(client.dio.close);
    expect(
      await EditProfileUseCase(profileRepository(client))(
        profileParams(dateOfBirth: today),
      ),
      isA<Success<User>>(),
    );
  });

  for (final entry in {
    400: 'Email is already in use.',
    401: 'Invalid or expired access token.',
    403: 'Account cannot use this application.',
    404: 'User not found.',
  }.entries) {
    test(
      '${entry.key} preserves server message and leaves cached profile unchanged',
      () async {
        final client = contractClient(
          (options) async => throw DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response<Object?>(
              requestOptions: options,
              statusCode: entry.key,
              data: {'message': entry.value},
            ),
          ),
        );
        addTearDown(client.dio.close);
        final result = await EditProfileUseCase(profileRepository(client))(
          profileParams(),
        );
        final failure = (result as ResultFailure<User>).failure;
        expect(failure.message, entry.value);
        if (entry.key == 401) {
          expect(failure, isA<TokenValidationFailure>());
        }
        expect(
          await const FlutterSecureStorage().read(key: 'user_info_key'),
          isNull,
        );
      },
    );
  }

  test('ASP.NET validation errors become readable domain feedback', () async {
    final client = contractClient(
      (options) async => throw DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response<Object?>(
          requestOptions: options,
          statusCode: 400,
          data: {
            'errors': {
              'Email': ['Enter a valid email address.'],
              'PhoneNumber': [
                'Phone number must contain 11 digits starting with 09.',
              ],
            },
          },
        ),
      ),
    );
    addTearDown(client.dio.close);
    final result = await EditProfileUseCase(profileRepository(client))(
      profileParams(),
    );
    expect(
      (result as ResultFailure).failure.message,
      'Enter a valid email address.\nPhone number must contain 11 digits starting with 09.',
    );
  });

  test(
    'malformed profile response returns a failure rather than a raw exception',
    () async {
      final client = contractClient(
        (options) async => reply(options, {'userId': 'invalid'}),
      );
      addTearDown(client.dio.close);
      expect(
        await EditProfileUseCase(profileRepository(client))(profileParams()),
        isA<ResultFailure<User>>(),
      );
      expect(
        await const FlutterSecureStorage().read(key: 'user_info_key'),
        isNull,
      );
    },
  );

  test('network exceptions become domain failures', () async {
    final client = contractClient(
      (options) async => throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      ),
    );
    addTearDown(client.dio.close);
    final result = await EditProfileUseCase(profileRepository(client))(
      profileParams(),
    );
    expect((result as ResultFailure).failure, isA<NetworkFailure>());
  });

  test(
    '401 refresh retries with the rotated access token before saving',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'old-access',
        'refresh_token': 'old-refresh',
        'refresh_expiration': '2099-01-01T00:00:00Z',
      });
      var requests = 0;
      late ApiClient client;
      client = contractClient(
        (options) async {
          if (options.path == '/auth/refresh') {
            expect(options.data, {'refresh_token': 'old-refresh'});
            return reply(options, {
              'access_token': 'new-access',
              'refresh_token': 'new-refresh',
              'refresh_token_expiration': '2099-02-01T00:00:00Z',
            });
          }
          requests++;
          if (requests == 1) {
            expect(options.headers['Authorization'], 'Bearer old-access');
            throw DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              response: Response<Object?>(
                requestOptions: options,
                statusCode: 401,
              ),
            );
          }
          expect(options.headers['Authorization'], 'Bearer new-access');
          return reply(options, profileResponse);
        },
        refreshAction: () async =>
            await contractRepository(client).refreshTokens() is Success,
      );
      addTearDown(client.dio.close);
      expect(
        await EditProfileUseCase(profileRepository(client))(profileParams()),
        isA<Success<User>>(),
      );
      expect(requests, 2);
      expect(
        await const FlutterSecureStorage().read(key: 'refresh_token'),
        'new-refresh',
      );
    },
  );

  test(
    'legacy cached address loads without inventing separate address fields',
    () {
      final legacy = UserModel.fromJson(profileResponse).toJson()
        ..remove('house_number')
        ..remove('street')
        ..remove('barangay')
        ..remove('city');
      final user = UserModel.fromJson(legacy).toEntity();
      expect(user.address, '123 J.P. Rizal Sta. Elena Marikina City');
      expect(user.houseNumber, isEmpty);
      expect(user.street, isEmpty);
    },
  );
}
