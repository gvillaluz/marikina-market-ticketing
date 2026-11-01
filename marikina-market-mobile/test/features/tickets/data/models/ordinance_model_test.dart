import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/severity.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_hive_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_model.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ordinance.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/ordinance_category.dart';

// Payload supplied with the updated ordinance contract.
const ordinanceResponse = <String, Object?>{
  'id': 1,
  'ordinance_no': 'Ord. No. 123 Series of 2026',
  'series': '2026',
  'section': '69',
  'title': 'Proper Waste Disposal',
  'category': 'Sanitation',
  'created_at': '2026-10-07T08:00:00Z',
  'updated_at': '2026-10-07T08:00:00Z',
  'is_active': true,
  'severity': 'Minor',
  'warning_eligible': true,
  'penalty_tier_count': 2,
};

void expectOrdinance(Ordinance ordinance) {
  expect(ordinance.id, 1);
  expect(ordinance.ordinanceNo, 'Ord. No. 123 Series of 2026');
  expect(ordinance.series, '2026');
  expect(ordinance.section, '69');
  expect(ordinance.sectionLabel, 'Section 69');
  expect(ordinance.title, 'Proper Waste Disposal');
  expect(ordinance.description, isEmpty);
  expect(ordinance.category, OrdinanceCategory.sanitation);
  expect(ordinance.severity, Severity.minor);
  expect(ordinance.createdAt, DateTime.utc(2026, 10, 7, 8));
  expect(ordinance.updatedAt, DateTime.utc(2026, 10, 7, 8));
  expect(ordinance.isActive, isTrue);
  expect(ordinance.penaltyTierCount, 2);
}

void main() {
  test('maps the complete ordinance response to its domain entity', () {
    expectOrdinance(OrdinanceModel.fromJson(ordinanceResponse).toEntity());
  });

  test('all ordinance fields survive the Hive adapter round trip', () {
    final adapter = OrdinanceHiveModelAdapter();
    final writer = BinaryWriterImpl(Hive);
    adapter.write(
      writer,
      OrdinanceHiveModel.fromModel(OrdinanceModel.fromJson(ordinanceResponse)),
    );
    final reader = BinaryReaderImpl(writer.toBytes(), Hive);
    expectOrdinance(adapter.read(reader).toEntity());
    expect(reader.availableBytes, 0);
  });

  test(
    'section and specific category survive Hive without using legacy codes',
    () {
      final adapter = OrdinanceHiveModelAdapter();
      final writer = BinaryWriterImpl(Hive);
      adapter.write(
        writer,
        OrdinanceHiveModel.fromModel(
          OrdinanceModel.fromJson({
            ...ordinanceResponse,
            'category': 'Others',
            'specific_category': 'Market clearance',
          }),
        ),
      );
      final cached = adapter.read(BinaryReaderImpl(writer.toBytes(), Hive));
      expect(cached.marketCode, isEmpty);
      expect(cached.ordinanceCode, isEmpty);
      expect(cached.toEntity().section, '69');
      expect(cached.toEntity().specificCategory, 'Market clearance');
      expect(cached.toEntity().categoryLabel, 'Others: Market clearance');
    },
  );

  test(
    'reads the thirteen-field cache without promoting SAMPLE codes to sections',
    () {
      final writer = BinaryWriterImpl(Hive)..writeByte(13);
      final legacyFields = <int, Object?>{
        0: 1,
        1: '11',
        2: 'SAMPLE-001',
        3: 'Market clearance',
        4: '',
        5: 'Licensing',
        6: DateTime.utc(2026, 10, 7, 8),
        7: 'Minor',
        8: '2014',
        9: 'SAMPLE-001',
        10: DateTime.utc(2026, 10, 8),
        11: false,
        12: 3,
      };
      for (final field in legacyFields.entries) {
        writer
          ..writeByte(field.key)
          ..write(field.value);
      }
      final cached = OrdinanceHiveModelAdapter().read(
        BinaryReaderImpl(writer.toBytes(), Hive),
      );
      expect(cached.marketCode, 'SAMPLE-001');
      expect(cached.ordinanceCode, 'SAMPLE-001');
      expect(cached.toEntity().section, isNull);
      expect(cached.toEntity().sectionLabel, 'Section unavailable');
      expect(cached.toEntity().specificCategory, isNull);
      expect(cached.toEntity().category, OrdinanceCategory.licensing);
      expect(cached.toEntity().isActive, isFalse);
    },
  );

  test(
    'Hive appends warning and tier rules without fabricating missing scoring',
    () {
      final model = OrdinanceModel.fromJson({
        ...ordinanceResponse,
        'severity': null,
        'warning_eligible': true,
        'penalty_tiers': [
          {
            'id': 1,
            'offense_number': 1,
            'fine_kind': 'UpTo',
            'penalty_amount': null,
            'minimum_fine': 100,
            'maximum_fine': 1000,
            'penalty_terms': 'Up to 1000',
            'allow_blood_donation': true,
            'allow_community_service': false,
          },
        ],
      });
      final adapter = OrdinanceHiveModelAdapter();
      final writer = BinaryWriterImpl(Hive);
      adapter.write(writer, OrdinanceHiveModel.fromModel(model));
      final cached = adapter
          .read(BinaryReaderImpl(writer.toBytes(), Hive))
          .toEntity();
      expect(cached.severity, isNull);
      expect(cached.warningEligible, isTrue);
      expect(cached.penaltyTiers.single.minimumFine, 100);
      expect(cached.penaltyTiers.single.maximumFine, 1000);
      expect(cached.penaltyTiers.single.allowBloodDonation, isTrue);
      expect(cached.penaltyTiers.single.allowCommunityService, isFalse);
    },
  );

  test('cache retains inactive status, changed timestamp, and zero tiers', () {
    final adapter = OrdinanceHiveModelAdapter();
    final writer = BinaryWriterImpl(Hive);
    adapter.write(
      writer,
      OrdinanceHiveModel.fromModel(
        OrdinanceModel.fromJson({
          ...ordinanceResponse,
          'updated_at': '2026-10-08T09:30:00Z',
          'is_active': false,
          'penalty_tier_count': 0,
        }),
      ),
    );
    final entity = adapter
        .read(BinaryReaderImpl(writer.toBytes(), Hive))
        .toEntity();
    expect(entity.isActive, isFalse);
    expect(entity.updatedAt, DateTime.utc(2026, 10, 8, 9, 30));
    expect(entity.penaltyTierCount, 0);
  });

  test('reads the previous eight-field cache without requiring a reset', () {
    final writer = BinaryWriterImpl(Hive)..writeByte(8);
    final legacyFields = <int, Object>{
      0: 1,
      1: 'Ord. No. 123 Series of 2026',
      2: 'MKT-001',
      3: 'Proper Waste Disposal',
      4: 'Vendors must dispose of waste in designated areas.',
      5: 'Sanitation',
      6: DateTime.utc(2026, 10, 7, 8),
      7: 'Minor',
    };
    for (final field in legacyFields.entries) {
      writer
        ..writeByte(field.key)
        ..write(field.value);
    }
    final entity = OrdinanceHiveModelAdapter()
        .read(BinaryReaderImpl(writer.toBytes(), Hive))
        .toEntity();
    expect(entity.id, 1);
    expect(entity.section, isNull);
    expect(entity.sectionLabel, 'Section unavailable');
    expect(
      entity.description,
      'Vendors must dispose of waste in designated areas.',
    );
    expect(entity.series, isEmpty);
    expect(entity.warningEligible, isNull);
    expect(entity.penaltyTiers, isEmpty);
    expect(entity.updatedAt, entity.createdAt);
    expect(entity.isActive, isTrue);
    expect(entity.penaltyTierCount, 0);
  });
}
