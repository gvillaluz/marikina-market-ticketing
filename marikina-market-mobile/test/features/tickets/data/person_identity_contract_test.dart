import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/person_candidate_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/inspection_verification_model.dart';

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

  test(
    'Verify retains the server review snapshot and authoritative offense position',
    () {
      final verified = InspectionVerificationModel.fromJson({
        'reviewed_calculation': 'server-reviewed-calculation',
        'calculation': {
          'total_payment_amount': 1500,
          'highest_severity': 'Minor',
          'breakdown': [
            {
              'ordinance_id': 5,
              'ordinance_no': '011',
              'ordinance_code': 'SAN',
              'payment_amount': 1500,
              'severity': 'Minor',
              'offense_number': 3,
              'category': 'Sanitation',
              'is_duplicate': false,
            },
          ],
        },
      }).toEntity();
      expect(verified.reviewedCalculation, 'server-reviewed-calculation');
      expect(verified.calculation.totalPaymentAmount, 1500);
      expect(verified.calculation.breakdownItems.single.offenseNumber, 3);
    },
  );
}
