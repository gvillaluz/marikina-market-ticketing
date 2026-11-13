import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ticket_detail_model.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/violator_detail_section.dart';

const snapshot = <String, Object?>{
  'business_account_number': 'SNAP-001',
  'business_name': 'Market Fish A',
  'registered_owner_name': 'Owner A',
  'business_type': 'Public',
  'stall_number': 'F-14',
  'market_section_name': 'Fish A',
  'business_address': '14 Market Lane',
};
Map<String, Object?> record(Object? saved) => {
  'ticket_id': 1,
  'enforcer_id': 3,
  'vendor_id': 1,
  'type': 'Ticket',
  'business_type': 'Public',
  'business_account_number': 'CURRENT-B',
  'business_name': 'Business B',
  'first_name': 'Current',
  'last_name': 'Owner B',
  'registered_owner_name': 'Current Owner B',
  'address': 'Current address B',
  'violations': <Object?>[],
  'issued_at': '2026-10-30T00:00:00Z',
  'market_section_name': 'Current Section B',
  'categories': <Object?>[],
  'description': 'Synthetic citation',
  'business_snapshot': saved,
};
void main() {
  testWidgets(
    'saved citation uses historical values instead of changed registry',
    (tester) async {
      final ticket = TicketDetailModel.fromJson(record(snapshot)).toEntity();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ViolatorDetailSection(ticket: ticket, isTicket: true),
            ),
          ),
        ),
      );
      expect(find.text('Owner A'), findsOneWidget);
      expect(find.text('Market Fish A'), findsOneWidget);
      expect(find.text('SNAP-001'), findsOneWidget);
      expect(find.text('14 Market Lane'), findsOneWidget);
      expect(find.text('Current Owner B'), findsNothing);
    },
  );
  testWidgets('legacy citation does not manufacture historical business data', (
    tester,
  ) async {
    final ticket = TicketDetailModel.fromJson(record(null)).toEntity();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ViolatorDetailSection(ticket: ticket, isTicket: true),
          ),
        ),
      ),
    );
    expect(
      find.text('Historical business details unavailable.'),
      findsOneWidget,
    );
    expect(find.text('Business B'), findsNothing);
    expect(find.text('Current address B'), findsNothing);
  });
}
