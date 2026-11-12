import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/duplicate_info_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/fine_breakdown_item_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/violation_summary_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/warning_ordinance_model.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/ordinance_category.dart';

const sectionResponse = <String, Object?>{
  'id': 53,
  'ordinance_no': '11',
  'series': '2014',
  'section': '53',
  'title': 'Restriction of use of streets and sidewalks',
  'category': 'Obstruction',
  'specific_category': null,
  'created_at': '2026-10-31T00:00:00Z',
  'updated_at': '2026-10-31T00:00:00Z',
  'is_active': true,
  'severity': 'Minor',
  'penalty_tier_count': 3,
};

void main() {
  test('reads section responses without the retired market code field', () {
    final ordinance = OrdinanceModel.fromJson(sectionResponse).toEntity();
    expect(ordinance.section, '53');
    expect(ordinance.sectionLabel, 'Section 53');
  });

  test('accepts unknown legacy section without fabricating one', () {
    final ordinance = OrdinanceModel.fromJson({
      ...sectionResponse,
      'section': null,
      'market_code': 'SAMPLE-001',
    }).toEntity();
    expect(ordinance.section, isNull);
    expect(ordinance.sectionLabel, 'Section unavailable');
  });

  test('Others retains the specific category and its readable label', () {
    final ordinance = OrdinanceModel.fromJson({
      ...sectionResponse,
      'category': 'Others',
      'specific_category': 'Market clearance',
    }).toEntity();
    expect(ordinance.specificCategory, 'Market clearance');
    expect(ordinance.categoryLabel, 'Market clearance');
  });

  test('a non-Others ordinance shows its category name', () {
    final ordinance = OrdinanceModel.fromJson(sectionResponse).toEntity();
    expect(ordinance.categoryLabel, 'Obstruction');
  });

  test(
    'all ticket response projections retain section and specific category',
    () {
      const response = <String, Object?>{
        'ordinance_id': 53,
        'ordinance_no': '11',
        'section': '53',
        'specific_category': 'Market clearance',
        'payment_amount': 1000,
        'penalty_amount': 1000,
        'severity': 'Minor',
        'offense_number': 2,
        'offense_count': 2,
        'is_duplicate': false,
      };
      final fine = FineBreakdownItemModel.fromJson(response).toEntity();
      final violation = ViolationSummaryModel.fromJson(response).toEntity();
      final warning = WarningOrdinanceModel.fromJson(response).toEntity();
      final duplicate = DuplicateInfoModel.fromJson(response).toEntity();
      expect(fine.detailsLabel, 'Section 53 · Market clearance');
      expect(violation.detailsLabel, fine.detailsLabel);
      expect(warning.detailsLabel, fine.detailsLabel);
      expect(duplicate.detailsLabel, fine.detailsLabel);
      expect(fine.paymentAmount, 1000);
      expect(fine.offenseNumber, 2);
      expect(violation.paymentAmount, 1000);
      expect(violation.offenseNumber, 2);
    },
  );

  test('warning check reads the section contract without ordinance code', () {
    expect(
      () => WarningOrdinanceModel.fromJson({
        'ordinance_id': 53,
        'ordinance_no': '11',
        'section': '53',
      }),
      returnsNormally,
    );
  });

  test('recognizes the revised categories while retaining legacy values', () {
    for (final category in [
      'DressCode',
      'IllegalVendor',
      'NonSmoking',
      'Others',
      'Licensing',
      'Noise',
    ]) {
      expect(() => OrdinanceCategory.fromValue(category), returnsNormally);
    }
  });
}
