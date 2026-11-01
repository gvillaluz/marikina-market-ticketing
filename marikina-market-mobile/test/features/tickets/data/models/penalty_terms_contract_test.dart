import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/fine_summary_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_model.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/fine_kind.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/assessed_fine_field.dart';

import 'ordinance_section_contract_test.dart' show sectionResponse;

const provisionalFine = <String, Object?>{
  'total_payment_amount': null,
  'highest_severity': null,
  'allow_blood_donation': false,
  'allow_community_service': false,
  'breakdown': [
    <String, Object?>{
      'ordinance_id': 53,
      'ordinance_no': '11',
      'section': '53',
      'payment_amount': null,
      'severity': null,
      'offense_number': 2,
      'is_duplicate': false,
      'fine_kind': 'Unconfirmed',
      'minimum_fine': null,
      'maximum_fine': null,
      'penalty_terms': 'Second offense is not stated.',
      'allow_blood_donation': false,
      'allow_community_service': false,
    },
  ],
};

void main() {
  test(
    'all selected first tiers must independently allow the same alternative and totals round cents',
    () {
      final base = Map<String, Object?>.from(
        (provisionalFine['breakdown'] as List).single as Map,
      );
      final summary = FineSummaryModel.fromJson({
        ...provisionalFine,
        'highest_severity': 'Minor',
        'breakdown': [
          {
            ...base,
            'ordinance_id': 1,
            'fine_kind': 'Fixed',
            'payment_amount': 0.10,
            'severity': 'Minor',
            'offense_number': 1,
            'allow_blood_donation': true,
            'allow_community_service': false,
          },
          {
            ...base,
            'ordinance_id': 2,
            'fine_kind': 'Fixed',
            'payment_amount': 0.20,
            'severity': 'Minor',
            'offense_number': 1,
            'allow_blood_donation': false,
            'allow_community_service': true,
          },
        ],
      }).toEntity().withAssessments({});
      expect(summary.totalPaymentAmount, 0.30);
      expect(summary.allowBloodDonation, isFalse);
      expect(summary.allowCommunityService, isFalse);
    },
  );
  test(
    'reads unavailable provisional assessment without inventing zero or Minor',
    () {
      final summary = FineSummaryModel.fromJson(provisionalFine).toEntity();
      expect(summary.totalPaymentAmount, isNull);
      expect(summary.severity, isNull);
      expect(summary.breakdownItems.single.paymentAmount, isNull);
      expect(
        summary.breakdownItems.single.penaltyTerms,
        'Second offense is not stated.',
      );
      expect(summary.isAssessable, isFalse);
    },
  );

  test(
    'an unclassified ordinance remains readable with independent warning eligibility',
    () {
      final ordinance = OrdinanceModel.fromJson({
        ...sectionResponse,
        'severity': null,
        'warning_eligible': true,
        'penalty_tiers': <Object?>[],
      }).toEntity();
      expect(ordinance.severity, isNull);
      expect(ordinance.warningEligible, isTrue);
      expect(ordinance.penaltyTiers, isEmpty);
    },
  );

  for (final kind in ['UpTo', 1]) {
    test(
      'UpTo $kind requires an explicitly assessed amount within server bounds',
      () {
        final itemJson = Map<String, Object?>.from(
          (provisionalFine['breakdown'] as List).single as Map,
        );
        final summary = FineSummaryModel.fromJson({
          ...provisionalFine,
          'highest_severity': 'High',
          'breakdown': [
            {
              ...itemJson,
              'severity': 'High',
              'offense_number': 1,
              'fine_kind': kind,
              'minimum_fine': 100,
              'maximum_fine': 1000,
              'allow_blood_donation': true,
              'allow_community_service': false,
            },
          ],
        }).toEntity();
        final item = summary.breakdownItems.single;
        expect(item.fineKind, FineKind.upTo);
        for (final invalid in [
          '',
          '99.99',
          '1000.01',
          '100.001',
          'NaN',
          'Infinity',
          '1e3',
          '-100',
        ]) {
          expect(parseAssessedFine(invalid, item), isNull, reason: invalid);
        }
        for (final text in ['100', '1000']) {
          final amount = parseAssessedFine(text, item)!;
          final assessed = summary.withAssessments({53: amount});
          expect(assessed.isAssessable, isTrue);
          expect(assessed.totalPaymentAmount, amount);
          expect(assessed.allowBloodDonation, isTrue);
          expect(assessed.allowCommunityService, isFalse);
        }
        expect(summary.withAssessments({}).totalPaymentAmount, isNull);
        expect(summary.withAssessments({}).isAssessable, isFalse);
        // Guard derived totals too, including callers restoring draft values.
        for (final amount in [
          99.99,
          1000.01,
          100.001,
          double.nan,
          double.infinity,
        ]) {
          final invalid = summary.withAssessments({53: amount});
          expect(invalid.isAssessable, isFalse, reason: '$amount');
          expect(invalid.totalPaymentAmount, isNull, reason: '$amount');
        }
      },
    );
  }

  test(
    'fixed amount remains exact, and later offenses disallow both alternatives',
    () {
      final item = Map<String, Object?>.from(
        (provisionalFine['breakdown'] as List).single as Map,
      );
      final summary = FineSummaryModel.fromJson({
        ...provisionalFine,
        'highest_severity': 'Minor',
        'total_payment_amount': 500,
        'breakdown': [
          {
            ...item,
            'fine_kind': 'Fixed',
            'payment_amount': 500,
            'severity': 'Minor',
            'allow_blood_donation': true,
            'allow_community_service': true,
          },
        ],
      }).toEntity().withAssessments({53: 100});
      expect(summary.breakdownItems.single.paymentAmount, 500);
      expect(summary.totalPaymentAmount, 500);
      expect(summary.allowBloodDonation, isFalse);
      expect(summary.allowCommunityService, isFalse);
    },
  );
}
