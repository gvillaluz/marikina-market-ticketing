import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/community_service_log.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/community_service_progress.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/ticket_receipt_proof.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ticket_settlement_data.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/community_service_log_section.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/settlement_receipt_section.dart';

void main() {
  testWidgets('saved receipt cannot be edited again', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettlementReceiptSection(
            settlement: const TicketSettlementData(
              ticketId: 1,
              penaltyType: PenaltyType.cashFine,
              ticketStatus: TicketStatus.pending,
              receiptProof: TicketReceiptProof(
                ticketId: 1,
                penaltyType: PenaltyType.cashFine,
                proofUrls: [],
              ),
              isReceiptSubmitted: true,
              isLoading: false,
              isLoaded: true,
              isSubmitting: false,
            ),
            onRetryLoad: () {},
            onSubmit: (_) {},
          ),
        ),
      ),
    );

    expect(
      find.text('Settlement receipt saved. This record cannot be changed.'),
      findsOneWidget,
    );
    expect(find.text('Tap to attach receipt photo'), findsNothing);
    expect(find.text('Save Receipt'), findsNothing);
  });

  testWidgets('paid ticket does not allow a receipt attachment', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettlementReceiptSection(
            settlement: const TicketSettlementData(
              ticketId: 1,
              penaltyType: PenaltyType.cashFine,
              ticketStatus: TicketStatus.paid,
              isReceiptSubmitted: false,
              isLoading: false,
              isLoaded: true,
              isSubmitting: false,
            ),
            onRetryLoad: () {},
            onSubmit: (_) {},
          ),
        ),
      ),
    );

    expect(
      find.text('This ticket is paid. Settlement details are read-only.'),
      findsOneWidget,
    );
    expect(find.text('Tap to attach receipt photo'), findsNothing);
    expect(find.text('Save Receipt'), findsNothing);
  });

  testWidgets('saved receipt proofs open the navigable evidence gallery', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettlementReceiptSection(
            settlement: const TicketSettlementData(
              ticketId: 1,
              penaltyType: PenaltyType.cashFine,
              ticketStatus: TicketStatus.pending,
              receiptProof: TicketReceiptProof(
                ticketId: 1,
                penaltyType: PenaltyType.cashFine,
                proofUrls: [
                  'https://example.com/receipt-1.jpg',
                  'https://example.com/receipt-2.jpg',
                ],
              ),
              isReceiptSubmitted: false,
              isLoading: false,
              isLoaded: true,
              isSubmitting: false,
            ),
            onRetryLoad: () {},
            onSubmit: (_) {},
          ),
        ),
      ),
    );

    final receiptImageTapTarget = find
        .ancestor(
          of: find.byType(Hero).first,
          matching: find.byType(GestureDetector),
        )
        .first;
    await tester.tap(receiptImageTapTarget);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Image 1 of 2'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('community service proofs open the navigable evidence gallery', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CommunityServiceLogSection(
              settlement: TicketSettlementData(
                ticketId: 2,
                penaltyType: PenaltyType.communityService,
                ticketStatus: TicketStatus.pending,
                requiredHours: 8,
                communityServiceProgress: CommunityServiceProgress(
                  ticketId: 2,
                  hoursRequired: 8,
                  hoursCompleted: 2,
                  hoursRemaining: 6,
                  completionPercentage: 25,
                  entries: [
                    CommunityServiceLog(
                      serviceDate: DateTime(2026, 9, 1),
                      hoursWorked: 1,
                      proofUrl: 'https://example.com/service-1.jpg',
                    ),
                    CommunityServiceLog(
                      serviceDate: DateTime(2026, 9, 2),
                      hoursWorked: 1,
                      proofUrl: 'https://example.com/service-2.jpg',
                    ),
                  ],
                ),
                isReceiptSubmitted: false,
                isLoading: false,
                isLoaded: true,
                isSubmitting: false,
              ),
              onRetryLoad: () {},
              onSubmit: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Sep 1, 2026'));
    await tester.pump();
    await tester.ensureVisible(find.byType(Hero).first);
    final serviceProofTapTarget = find
        .ancestor(
          of: find.byType(Hero).first,
          matching: find.byType(GestureDetector),
        )
        .first;
    await tester.tap(serviceProofTapTarget);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Image 1 of 2'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('service form rejects excess hours and excess decimal places', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CommunityServiceLogSection(
              settlement: const TicketSettlementData(
                ticketId: 2,
                penaltyType: PenaltyType.communityService,
                ticketStatus: TicketStatus.inProgress,
                requiredHours: 8,
                communityServiceProgress: CommunityServiceProgress(
                  ticketId: 2,
                  hoursRequired: 8,
                  hoursCompleted: 2,
                  hoursRemaining: 6,
                  completionPercentage: 25,
                  entries: [],
                ),
                isReceiptSubmitted: false,
                isLoading: false,
                isLoaded: true,
                isSubmitting: false,
              ),
              onRetryLoad: () {},
              onSubmit: (_) => fail('Invalid hours must not be submitted.'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Add Service Entry'));
    await tester.pumpAndSettle();
    for (final (value, message) in [
      ('7', 'Hours cannot exceed the remaining 6 hours.'),
      ('0.123', 'Use at most 2 decimal places.'),
    ]) {
      await tester.enterText(find.byType(TextFormField), value);
      await tester.ensureVisible(find.text('Log Hours'));
      await tester.tap(find.text('Log Hours'));
      await tester.pumpAndSettle();
      expect(find.text(message), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('completed community service log is read-only', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CommunityServiceLogSection(
            settlement: const TicketSettlementData(
              ticketId: 2,
              penaltyType: PenaltyType.communityService,
              ticketStatus: TicketStatus.pending,
              requiredHours: 8,
              communityServiceProgress: CommunityServiceProgress(
                ticketId: 2,
                hoursRequired: 8,
                hoursCompleted: 8,
                hoursRemaining: 0,
                completionPercentage: 100,
                entries: [],
              ),
              isReceiptSubmitted: false,
              isLoading: false,
              isLoaded: true,
              isSubmitting: false,
            ),
            onRetryLoad: () {},
            onSubmit: (_) {},
          ),
        ),
      ),
    );

    expect(
      find.text('Required community service hours are complete.'),
      findsOneWidget,
    );
    expect(find.text('Add Service Entry'), findsNothing);
  });
}
