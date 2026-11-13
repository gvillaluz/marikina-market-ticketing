import 'package:marikina_market_mobile/features/tickets/domain/entities/business_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ticket_detail.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/violation_summary.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/business_type.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/violator_detail_section.dart';

void main() {
  testWidgets('shows business id and unavailable address for ticket', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ViolatorDetailSection(
            ticket: _ticket(address: '  '),
            isTicket: true,
          ),
        ),
      ),
    );

    expect(find.text('BUSINESS ID:'), findsOneWidget);
    expect(find.text('BUS-123'), findsOneWidget);
    expect(find.text('ADDRESS:'), findsOneWidget);
    expect(find.text('Address is unavailable.'), findsOneWidget);
    expect(find.text('STALL/UNIT NO:'), findsOneWidget);
    expect(find.text('CONFIRMED PERSON:'), findsNothing);
  });

  for (final isTicket in [true, false]) {
    testWidgets('hides stall/unit number for a private business '
        '(ticket=$isTicket)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ViolatorDetailSection(
              ticket: _ticket(
                address: 'Marikina',
                type: 'Private',
                businessType: BusinessType.private,
              ),
              isTicket: isTicket,
            ),
          ),
        ),
      );
      expect(find.text('STALL/UNIT NO:'), findsNothing);
      expect(find.text('BUSINESS ID:'), findsOneWidget);
    });
  }
}

TicketDetail _ticket({
  required String? address,
  String type = 'Public',
  BusinessType businessType = BusinessType.public,
}) => TicketDetail(
  businessSnapshot: BusinessSnapshot(
    businessAccountNumber: 'BUS-123',
    businessName: 'Market Store',
    registeredOwnerName: 'Jane Doe',
    businessType: type,
    stallNumber: 'A-12',
    marketSectionName: 'Section A',
    businessAddress: address,
  ),
  ticketId: 1,
  enforcerId: 2,
  enforcerName: 'Reyes, Ana',
  vendorId: 3,
  violationType: ViolationType.ticket,
  businessType: businessType,
  stallNumber: 'A-12',
  businessAccountNumber: 'BUS-123',
  tradeName: 'Market Store',
  lastName: 'Doe',
  firstName: 'Jane',
  address: address,
  violations: const <ViolationSummary>[],
  issuedAt: DateTime(2026),
  marketSectionName: 'Section A',
  categories: const [],
  description: '',
);
