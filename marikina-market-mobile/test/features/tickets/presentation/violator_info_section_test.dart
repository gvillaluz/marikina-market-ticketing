import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/preview/violator_info_section.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/ticket_paper_field_group.dart';

import '../../../inspection_preview_navigation_test.dart' show vendor;

// Every labelled line of the section, by label.
Map<String, String> lines(WidgetTester tester) => {
  for (final group in tester.widgetList<TicketPaperFieldGroup>(
    find.byType(TicketPaperFieldGroup),
  ))
    for (final field in group.fields) field.label: field.value,
};

Future<void> show(
  WidgetTester tester, {
  String? personAddress,
  bool isTicket = true,
  int? personId = 31,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: ViolatorInfoSection(
          vendor: vendor,
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
  testWidgets('business and violator addresses are labelled separately', (
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
