import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/ticket_violation_section.dart';

void main() {
  final issuedAt = DateTime(2026, 11, 18, 19, 10);
  const issuedText = 'November 18, 2026 • 7:10 PM';

  Future<void> pumpSection(
    WidgetTester tester, {
    required bool isTicket,
    DateTime? issuedAt,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: TicketViolationSection(
              violations: const [],
              description: 'Obstructed aisle',
              marketSection: 'Section A',
              categories: const [],
              isTicket: isTicket,
              penaltyType: isTicket ? PenaltyType.cashFine : null,
              issuedAt: issuedAt,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('a ticket shows the time it was issued', (tester) async {
    await pumpSection(tester, isTicket: true, issuedAt: issuedAt);

    expect(find.text(issuedText), findsOneWidget);
  });

  testWidgets('a warning shows the time it was issued', (tester) async {
    await pumpSection(tester, isTicket: false, issuedAt: issuedAt);

    expect(find.text(issuedText), findsOneWidget);
  });

  testWidgets('a ticket with no issue time says it is unavailable', (
    tester,
  ) async {
    await pumpSection(tester, isTicket: true);

    expect(find.text('Unavailable (legacy record)'), findsWidgets);
    expect(find.textContaining('•'), findsNothing);
  });
}
