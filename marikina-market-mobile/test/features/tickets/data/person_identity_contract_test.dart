import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/fine_summary_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/person_candidate_model.dart';

void main() {
  test(
    'same name candidates retain distinct person IDs and supporting fields',
    () {
      final people = [31, 32]
          .map(
            (id) => PersonCandidateModel.fromJson({
              'id': id,
              'full_name': 'Juan Dela Cruz',
              'address': '$id Market Lane',
              'phone_number': null,
              'matched_fields': ['name'],
            }).toEntity(),
          )
          .toList();
      expect(people.map((p) => p.id), [31, 32]);
      expect(people.first.address, '31 Market Lane');
      expect(people.first.matchedFields, ['name']);
    },
  );

  test('the fine summary retains the authoritative offense position', () {
    final summary = FineSummaryModel.fromJson({
      'total_payment_amount': 1500,
      'highest_severity': 'Minor',
      'breakdown': [
        {
          'ordinance_id': 5,
          'ordinance_no': '011',
          'section': '66',
          'payment_amount': 1500,
          'fine_kind': 'Fixed',
          'severity': 'Minor',
          'offense_number': 3,
          'category': 'Sanitation',
          'is_duplicate': false,
        },
      ],
    }).toEntity();
    expect(summary.totalPaymentAmount, 1500);
    expect(summary.breakdownItems.single.offenseNumber, 3);
  });
}
