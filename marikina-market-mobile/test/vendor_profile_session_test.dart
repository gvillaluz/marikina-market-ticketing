import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/auth/data/models/user_model.dart';
import 'package:marikina_market_mobile/features/auth/domain/entities/user.dart';
import 'package:marikina_market_mobile/features/profile/domain/use_cases/edit_profile_use_case.dart';
import 'package:marikina_market_mobile/features/profile/data/data_sources/profile_remote_data_source.dart';
import 'package:marikina_market_mobile/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:marikina_market_mobile/features/profile/domain/use_cases/change_password_use_case.dart';
import 'package:marikina_market_mobile/core/utils/unit.dart';
import 'features/auth/data/login_mobile_contract_test.dart' as auth;
import 'features/profile/profile_contract_test.dart' as profile;

const vendorBusiness = <String, Object?>{
  'vendor_id': 70,
  'business_id': 'MM-70',
  'business_name': 'Reyes Fresh Fish',
  'stall_number': 'F-12',
  'market_section_id': 2,
  'market_section_name': 'Fish and Seafood',
  'type': 'Public',
  'status': 'Active',
  'qr_code_value': 'test-vendor-token-70',
};
final vendorAccount = <String, Object?>{
  ...profile.profileResponse,
  'username': 'juan.reyes',
  'lastName': 'Reyes',
  'email': 'juan.reyes@example.invalid',
  'role': 'MarketVendor',
  'vendor': vendorBusiness,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'mandatory password change preserves cached vendor business information',
    () async {
      final client = auth.contractClient((options) async {
        expect(options.path, '/auth/mandatory-change-password');
        return auth.reply(options, null);
      });
      addTearDown(client.dio.close);
      final repository = auth.contractRepository(client);
      await repository.localDataSource.storeUser(
        UserModel.fromJson({...vendorAccount, 'mustChangedPassword': true}),
      );
      final result = await repository.mandatoryChangePassword(
        7,
        'OldPass123',
        'NewPass123',
        'NewPass123',
      );
      expect(result, isA<Success<User>>());
      expect(
        (result as Success<User>).data.vendor?.businessName,
        vendorBusiness['business_name'],
      );
      final saved = await repository.localDataSource.getUser();
      expect(saved.toJson()['vendor'], vendorBusiness);
      expect(saved.mustChangePassword, isFalse);
    },
  );

  test(
    'login caches vendor business and QR with the account snapshot',
    () async {
      final requests = <String>[];
      final client = auth.contractClient((options) async {
        requests.add(options.path);
        return auth.reply(
          options,
          options.path == '/auth/verify-login-mobile'
              ? auth.tokenResponse
              : vendorAccount,
        );
      });
      addTearDown(client.dio.close);
      final repo = auth.contractRepository(client);
      final result = await repo.verifyLogin(
        'vendor07',
        'ExamplePass123',
        '001234',
      );
      expect(result, isA<Success<User>>());
      final cached = await repo.localDataSource.getUser();
      expect(cached.toJson()['vendor'], vendorBusiness);
      final restored = UserModel.fromEntity(cached.toEntity()).toJson();
      expect(restored['vendor'], vendorBusiness);
      expect(requests, ['/auth/verify-login-mobile', '/user/me']);
    },
  );

  test(
    'vendor edit uses its endpoint and replaces the secure cached snapshot',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'test-access-token',
      });
      final client = auth.contractClient((options) async {
        expect(options.method, 'PUT');
        expect(options.path, '/vendor/profile');
        expect(options.data, isNot(contains('user_id')));
        return auth.reply(options, {
          'user': {...vendorAccount, 'firstName': 'Juana'},
          'vendor': vendorBusiness,
        });
      });
      addTearDown(client.dio.close);
      final repo = auth.contractRepository(client);
      await repo.localDataSource.storeUser(UserModel.fromJson(vendorAccount));
      final result = await EditProfileUseCase(
        ProfileRepositoryImpl(
          ProfileRemoteDataSourceImpl(client, isVendor: true),
          repo,
        ),
      )(profile.profileParams(firstName: 'Juana'));
      expect(result, isA<Success<User>>());
      final stored = await repo.localDataSource.getUser();
      expect(stored.firstName, 'Juana');
      expect(stored.toJson()['vendor'], vendorBusiness);
    },
  );

  test(
    'both roles retain the existing shared password validation rules',
    () async {
      var requests = 0;
      final client = auth.contractClient((_) async {
        requests++;
        throw StateError('Invalid passwords must not be sent.');
      });
      addTearDown(client.dio.close);
      final useCase = ChangePasswordUseCase(profile.profileRepository(client));
      for (final entry in [
        ('', 'NewPass123', 'NewPass123', 'All password fields are required.'),
        (
          'OldPass123',
          'short',
          'short',
          'New password must be at least 8 characters long.',
        ),
        (
          'OldPass123',
          'NewPass123',
          'Different123',
          'New passwords do not match.',
        ),
        (
          'OldPass123',
          'OldPass123',
          'OldPass123',
          'New password cannot be the same as your current password.',
        ),
      ]) {
        final result = await useCase(
          ChangePasswordParams(
            userId: 7,
            currentPassword: entry.$1,
            newPassword: entry.$2,
            confirmNewPassword: entry.$3,
          ),
        );
        expect((result as ResultFailure<Unit>).failure.message, entry.$4);
      }
      expect(requests, 0);
    },
  );

  test(
    'password change stays online and preserves the existing request',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'test-access-token',
      });
      var requests = 0;
      final client = auth.contractClient((options) async {
        requests++;
        expect(options.path, '/auth/change-password');
        expect(options.method, 'POST');
        expect(options.data, {
          'user_id': 7,
          'current_password': 'OldPass123',
          'new_password': ' NewPass123 ',
          'confirm_new_password': ' NewPass123 ',
        });
        return auth.reply(options, null);
      });
      addTearDown(client.dio.close);
      final result =
          await ChangePasswordUseCase(profile.profileRepository(client))(
            ChangePasswordParams(
              userId: 7,
              currentPassword: 'OldPass123',
              newPassword: ' NewPass123 ',
              confirmNewPassword: ' NewPass123 ',
            ),
          );
      expect(result, isA<Success<Unit>>());
      expect(requests, 1);
    },
  );
}
