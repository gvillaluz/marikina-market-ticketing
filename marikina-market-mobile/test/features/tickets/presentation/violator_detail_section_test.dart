import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ticket_detail.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/violation_summary.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/vendor_type.dart';
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
  });
}

TicketDetail _ticket({required String? address}) => TicketDetail(
  ticketId: 1,
  enforcerId: 2,
  vendorId: 3,
  violationType: ViolationType.ticket,
  vendorType: VendorType.public,
  businessId: 'BUS-123',
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
