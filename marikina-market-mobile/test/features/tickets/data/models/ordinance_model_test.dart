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
  'market_code': 'MKT-001',
  'title': 'Proper Waste Disposal',
  'category': 'Sanitation',
  'created_at': '2026-10-07T08:00:00Z',
  'updated_at': '2026-10-07T08:00:00Z',
  'is_active': true,
  'severity': 'Minor',
  'penalty_tier_count': 2,
};

void expectOrdinance(Ordinance ordinance) {
  expect(ordinance.id, 1);
  expect(ordinance.ordinanceNo, 'Ord. No. 123 Series of 2026');
  expect(ordinance.series, '2026');
  expect(ordinance.marketCode, 'MKT-001');
  expect(ordinance.ordinanceCode, 'MKT-001');
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
    expect(entity.ordinanceCode, 'MKT-001');
    expect(entity.marketCode, 'MKT-001');
    expect(
      entity.description,
      'Vendors must dispose of waste in designated areas.',
    );
    expect(entity.series, isEmpty);
    expect(entity.updatedAt, entity.createdAt);
    expect(entity.isActive, isTrue);
    expect(entity.penaltyTierCount, 0);
  });
}
