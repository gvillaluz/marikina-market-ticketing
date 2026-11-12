import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/business_snapshot.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/preview/violator_info_section.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/ticket_paper_field.dart';

import '../../../inspection_preview_navigation_test.dart' show vendor;

// Every labelled line of the section, by label.
Map<String, String> lines(WidgetTester tester) => {
  for (final field in tester.widgetList<TicketPaperField>(
    find.byType(TicketPaperField),
  ))
    field.label: field.value,
};

Future<void> show(
  WidgetTester tester, {
  BusinessSnapshot? snapshot,
  String? personAddress,
  bool isTicket = true,
  int? personId = 31,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: ViolatorInfoSection(
          vendor: vendor,
          businessSnapshot: snapshot,
          personId: personId,
          personFullName: 'Juan Dela Cruz',
          personAddress: personAddress,
          paperViolatorName: 'Juan Dela Cruz',
          isTicket: isTicket,
        ),
      ),
    ),
  ),
);

void main() {
  const snapshot = BusinessSnapshot(
    businessAccountNumber: 'TEST-12',
    businessName: 'Synthetic Market Goods',
    registeredOwnerName: 'Synthetic Vendor',
    businessType: 'Public',
    stallNumber: 'A-12',
    marketSectionName: 'Section A',
    businessAddress: '14 Business Lane',
  );

  testWidgets('reviewed business: business and violator addresses differ', (
    tester,
  ) async {
    await show(
      tester,
      snapshot: snapshot,
      personAddress: '31 Synthetic Market Lane',
    );
    final shown = lines(tester);
    expect(shown['BUSINESS ADDRESS:'], '14 Business Lane');
    expect(shown['VIOLATOR ADDRESS:'], '31 Synthetic Market Lane');
    expect(shown.containsKey('ADDRESS:'), isFalse);
  });

  testWidgets('before Verify: current business address is labelled too', (
    tester,
  ) async {
    await show(tester, personAddress: '31 Synthetic Market Lane');
    final shown = lines(tester);
    expect(shown['BUSINESS ADDRESS:'], 'Synthetic Street, Marikina');
    expect(shown['VIOLATOR ADDRESS:'], '31 Synthetic Market Lane');
    expect(shown.containsKey('ADDRESS:'), isFalse);
  });

  testWidgets('warnings show no address lines', (tester) async {
    await show(
      tester,
      snapshot: snapshot,
      personAddress: '31 Synthetic Market Lane',
      isTicket: false,
    );
    final shown = lines(tester);
    expect(shown.containsKey('VIOLATOR ADDRESS:'), isFalse);
    expect(shown.containsKey('ADDRESS:'), isFalse);
  });

  testWidgets('confirmed person shows only the person name', (tester) async {
    await show(tester);
    expect(lines(tester)['CONFIRMED PERSON:'], 'Juan Dela Cruz');
    expect(find.textContaining('Person 31'), findsNothing);
  });

  testWidgets('no chosen person shows Unconfirmed', (tester) async {
    await show(tester, personId: null);
    expect(lines(tester)['CONFIRMED PERSON:'], 'Unconfirmed');
  });
}
