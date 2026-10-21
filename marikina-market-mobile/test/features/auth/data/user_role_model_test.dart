import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/errors/exceptions.dart';
import 'package:marikina_market_mobile/core/storage/secure_storage_service_impl.dart';
import 'package:marikina_market_mobile/features/auth/data/data_sources/auth_local_data_source.dart';
import 'package:marikina_market_mobile/features/auth/data/models/user_model.dart';
import 'package:marikina_market_mobile/features/auth/domain/enums/role.dart';

import 'login_mobile_contract_test.dart' show profileResponse;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('role enum contains exactly the four backend roles', () {
    expect(Role.values.map((role) => role.value), [
      'HeadAdmin',
      'AdminOfficer',
      'MarketEnforcer',
      'MarketVendor',
    ]);
  });

  for (final role in [
    'HeadAdmin',
    'AdminOfficer',
    'MarketEnforcer',
    'MarketVendor',
  ]) {
    test('$role survives API, entity, and secure-cache mapping distinctly', () {
      final model = UserModel.fromJson({...profileResponse, 'role': role});
      final entity = model.toEntity();
      final cache = UserModel.fromEntity(entity).toJson();
      expect(entity.role.value, role);
      expect(cache['role'], role);
      expect(UserModel.fromJson(cache).role, Role.fromValue(role));
    });
  }

  for (final entry in {
    'Enforcer': 'MarketEnforcer',
    'Vendor': 'MarketVendor',
  }.entries) {
    test(
      'migrates cached ${entry.key} without accepting it as an API role',
      () {
        final cache = UserModel.fromJson(profileResponse).toJson()
          ..['role'] = entry.key;
        final model = UserModel.fromJson(cache);
        expect(model.role.value, entry.value);
        expect(model.toJson()['role'], entry.value);
        expect(
          () => UserModel.fromJson({...profileResponse, 'role': entry.key}),
          throwsArgumentError,
        );
      },
    );
  }

  test(
    'ambiguous Admin cache becomes a cache failure requiring fresh sign-in',
    () async {
      final cache = UserModel.fromJson(profileResponse).toJson()
        ..['role'] = 'Admin';
      FlutterSecureStorage.setMockInitialValues({
        'user_info_key': jsonEncode(cache),
      });
      final local = AuthLocalDataSourceImpl(
        storageService: const SecureStorageServiceImpl(
          storage: FlutterSecureStorage(),
        ),
      );
      await expectLater(local.getUser(), throwsA(isA<CacheException>()));
      expect(() => Role.fromValue('Admin'), throwsArgumentError);
    },
  );
}
