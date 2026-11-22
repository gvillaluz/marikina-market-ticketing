import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/penalty_options_model.dart';

// The sample from spec-change-penalty.md 5.1.
const _sample = <String, Object?>{
  'ticket_id': 42,
  'current_penalty_type': 'CashFine',
  'allowed_penalty_types': ['CashFine', 'CommunityService'],
  'cash_fine_amount': 1500.00,
  'community_service_hours': null,
  'version': 8812,
};

void main() {
  test('reads the contract sample', () {
    final options = PenaltyOptionsModel.fromJson(_sample).toEntity();

    expect(options.ticketId, 42);
    expect(options.currentPenaltyType, PenaltyType.cashFine);
    expect(options.allowedPenaltyTypes, [
      PenaltyType.cashFine,
      PenaltyType.communityService,
    ]);
    expect(options.cashFineAmount, 1500);
    expect(options.communityServiceHours, isNull);
    expect(options.version, 8812);
  });

  test('reads a whole-number amount, hours and a missing amount', () {
    final whole = PenaltyOptionsModel.fromJson({
      ..._sample,
      'cash_fine_amount': 200,
      'community_service_hours': 8,
    }).toEntity();
    final missing = PenaltyOptionsModel.fromJson({
      ..._sample,
      'cash_fine_amount': null,
    }).toEntity();

    expect(whole.cashFineAmount, 200);
    expect(whole.communityServiceHours, 8);
    expect(missing.cashFineAmount, isNull);
  });

  test('refuses an unknown penalty', () {
    expect(
      () => PenaltyOptionsModel.fromJson({
        ..._sample,
        'allowed_penalty_types': ['Jail'],
      }),
      throwsArgumentError,
    );
  });
}
