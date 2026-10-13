import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/shared/data/models/community_service_progress_model.dart';
import 'package:marikina_market_mobile/core/shared/data/models/ticket_receipt_proof_model.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';

void main() {
  group('TicketReceiptProofModel', () {
    test('parses receipt proof response', () {
      final model = TicketReceiptProofModel.fromJson({
        'ticket_id': 14,
        'penalty_type': 'CashFine',
        'proof_urls': ['https://example.com/receipt.jpg'],
      });

      final entity = model.toEntity();
      expect(entity.ticketId, 14);
      expect(entity.penaltyType, PenaltyType.cashFine);
      expect(entity.proofUrls, ['https://example.com/receipt.jpg']);
    });
  });

  group('CommunityServiceProgressModel', () {
    test('parses progress and expanded entry details', () {
      final model = CommunityServiceProgressModel.fromJson({
        'ticket_id': 27,
        'hours_required': 16,
        'hours_completed': 6.5,
        'hours_remaining': 9.5,
        'completion_percentage': 40.625,
        'entries': [
          {
            'service_date': '2026-09-26T00:00:00',
            'hours_worked': 4.5,
            'proof_url': 'https://example.com/proof.jpg',
          },
        ],
      });

      final progress = model.toEntity();
      expect(progress.ticketId, 27);
      expect(progress.hoursRequired, 16);
      expect(progress.hoursCompleted, 6.5);
      expect(progress.hoursRemaining, 9.5);
      expect(progress.completionPercentage, 40.625);
      expect(progress.entries, hasLength(1));
      expect(progress.entries.single.serviceDate, DateTime(2026, 9, 26));
      expect(progress.entries.single.hoursWorked, 4.5);
      expect(progress.entries.single.proofUrl, 'https://example.com/proof.jpg');
    });
  });
}
