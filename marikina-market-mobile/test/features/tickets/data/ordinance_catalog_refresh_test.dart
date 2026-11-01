import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:marikina_market_mobile/core/errors/exceptions.dart';
import 'package:marikina_market_mobile/core/errors/failure.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/tickets/data/data_sources/inspection_local_data_source.dart';
import 'package:marikina_market_mobile/features/tickets/data/data_sources/inspection_remote_data_source.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_hive_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/repositories/inspection_repository_impl.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ordinance.dart';

import 'models/ordinance_section_contract_test.dart' show sectionResponse;

class CatalogRemote extends Fake implements InspectionRemoteDataSource {
  Future<List<OrdinanceModel>> Function() response;
  int calls = 0;
  CatalogRemote(this.response);

  @override
  Future<List<OrdinanceModel>> getOrdinances() {
    calls++;
    return response();
  }
}

void main() {
  late Directory temporaryDirectory;
  late Box<OrdinanceHiveModel> box;
  late InspectionLocalDataSource local;
  late CatalogRemote remote;
  late InspectionRepositoryImpl repository;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'ordinance-catalog-refresh-',
    );
    Hive.init(temporaryDirectory.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(OrdinanceHiveModelAdapter());
    }
    box = await Hive.openBox<OrdinanceHiveModel>('ordinance-refresh-test');
    local = InspectionLocalDataSourceImpl(box);
    remote = CatalogRemote(
      () async => [
        OrdinanceModel.fromJson({
          ...sectionResponse,
          'category': 'Others',
          'specific_category': 'Market clearance',
        }),
      ],
    );
    repository = InspectionRepositoryImpl(remote, local);
  });

  tearDown(() async {
    await box.close();
    await temporaryDirectory.delete(recursive: true);
  });

  Future<void> seedLegacyCache() => box.add(
    OrdinanceHiveModel(
      ordinanceId: 1,
      ordinanceNo: '104',
      ordinanceCode: 'SAMPLE-002',
      title: 'Market identification card',
      description: '',
      category: 'Licensing',
      createdAt: DateTime.utc(2026, 10, 7),
      severity: 'Minor',
      series: '2007',
      marketCode: 'SAMPLE-002',
    ),
  );

  test(
    'refreshes a nonempty legacy catalog and saves current section and custom category',
    () async {
      await seedLegacyCache();
      final result = await repository.loadOrdinances();
      expect(remote.calls, 1);
      final ordinances = (result as Success<List<Ordinance>>).data;
      expect(ordinances.single.id, 53);
      expect(ordinances.single.section, '53');
      expect(ordinances.single.categoryLabel, 'Others: Market clearance');
      final cached = (await local.getCacheOrdinances()).single.toEntity();
      expect(cached.id, 53);
      expect(cached.section, '53');
      expect(cached.specificCategory, 'Market clearance');
      await repository.loadOrdinances();
      expect(remote.calls, 2);
    },
  );

  test(
    'uses and preserves saved ordinances when the network is unavailable',
    () async {
      await seedLegacyCache();
      remote.response = () async =>
          throw NetworkException('Connection unavailable.');
      final result = await repository.loadOrdinances();
      expect(remote.calls, 1);
      expect((result as Success<List<Ordinance>>).data.single.id, 1);
      expect(box.values.single.ordinanceCode, 'SAMPLE-002');
      expect(box.values.single.section, isNull);
    },
  );

  test(
    'returns NetworkFailure when the network is unavailable and no cache exists',
    () async {
      remote.response = () async =>
          throw NetworkException('Connection unavailable.');
      final result = await repository.loadOrdinances();
      final failure = (result as ResultFailure<List<Ordinance>>).failure;
      expect(failure, isA<NetworkFailure>());
      expect(failure.message, 'Connection unavailable.');
      expect(box.isEmpty, isTrue);
    },
  );

  for (final exception in [
    UnauthorizedException('Sign in again.'),
    ValidationException('Catalog request rejected.'),
    ServerException('Catalog service unavailable.'),
  ]) {
    test(
      'does not mask ${exception.runtimeType} with cached success',
      () async {
        await seedLegacyCache();
        remote.response = () async => throw exception;
        final result = await repository.loadOrdinances();
        expect(remote.calls, 1);
        final failure = (result as ResultFailure<List<Ordinance>>).failure;
        expect(failure, switch (exception) {
          UnauthorizedException() => isA<UnauthorizedFailure>(),
          ValidationException() => isA<ValidationFailure>(),
          _ => isA<ServerFailure>(),
        });
        expect(box.values.single.ordinanceCode, 'SAMPLE-002');
        expect(box.values.single.section, isNull);
      },
    );
  }

  test(
    'a successful empty remote catalog replaces outdated cached ordinances',
    () async {
      await seedLegacyCache();
      remote.response = () async => [];
      final result = await repository.loadOrdinances();
      expect(remote.calls, 1);
      expect((result as Success<List<Ordinance>>).data, isEmpty);
      expect(box.isEmpty, isTrue);
    },
  );
}
