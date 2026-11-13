import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/severity.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/business_snapshot.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/inspection_ticket_summary.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/inspection_card.dart';

InspectionTicketSummary ticket({
  String? stall,
  List<String> ordinances = const ['Keep the stall clean.'],
}) => InspectionTicketSummary(
  businessSnapshot: BusinessSnapshot(
    businessName: 'Market Goods',
    stallNumber: stall,
    marketSectionName: 'Section A',
  ),
  paperReference: '000456',
  issuePlace: 'Main gate',
  paperViolatorName: 'Maria Santos',
  ticketId: 42,
  ticketType: ViolationType.ticket,
  vendorId: 12,
  vendorFirstName: 'Maria',
  vendorLastName: 'Santos',
  businessName: 'Market Goods',
  marketSectionId: 1,
  marketSection: 'Section A',
  enforcerId: 7,
  businessType: null,
  businessAccountNumber: null,
  stallNumber: stall,
  severity: Severity.moderate,
  ordinance: ordinances,
  issuedAt: DateTime.utc(2026, 10, 7, 8),
  overDueDate: null,
  updatedAt: DateTime.utc(2026, 10, 7, 8),
);

InspectionTicketSummary warning() => InspectionTicketSummary(
  ticketId: 43,
  ticketType: ViolationType.warning,
  personFullName: 'Maria Santos',
  vendorId: 12,
  vendorFirstName: 'Maria',
  vendorLastName: 'Santos',
  businessName: 'Market Goods',
  marketSectionId: 1,
  marketSection: 'Section A',
  enforcerId: 7,
  businessType: null,
  businessAccountNumber: null,
  stallNumber: '12',
  severity: Severity.moderate,
  ordinance: const ['Keep the stall clean.'],
  issuedAt: DateTime.utc(2026, 10, 7, 8),
  overDueDate: null,
  updatedAt: DateTime.utc(2026, 10, 7, 8),
);

Future<void> show(
  WidgetTester tester,
  InspectionTicketSummary summary, {
  double width = 360,
  double textScale = 1,
  bool expanded = true,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: StatefulBuilder(
                builder: (context, setState) => InspectionCard(
                  ticketSummary: summary,
                  expanded: expanded,
                  onToggle: () => setState(() => expanded = !expanded),
                ),
              ),
            ),
          ),
        ),
      ),
      GoRoute(
        name: 'ticketDetail',
        path: '/tickets/:ticketId',
        builder: (_, _) => const Scaffold(body: Text('details opened')),
      ),
    ],
  );
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: Size(width, 900),
        textScaler: TextScaler.linear(textScale),
      ),
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
}

void main() {
  testWidgets('no stall number: no Unavailable text and no Stall label', (
    tester,
  ) async {
    await show(tester, ticket(stall: null));
    expect(find.text('Section A'), findsOneWidget);
    expect(find.textContaining('Stall'), findsNothing);
    expect(find.textContaining('Unavailable'), findsNothing);
  });

  testWidgets('stall number is shown as Stall 12', (tester) async {
    await show(tester, ticket(stall: '12'));
    expect(find.text('Section A • Stall 12'), findsOneWidget);
  });

  testWidgets('place and person lines each start with an icon', (tester) async {
    await show(tester, ticket(stall: '12'));
    expect(find.byIcon(Icons.place_outlined), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.text('Maria Santos'), findsOneWidget);
  });

  testWidgets('one ordinance is shown with no more-line', (tester) async {
    await show(tester, ticket(ordinances: ['Ordinance one']));
    expect(find.text('Ordinance one'), findsOneWidget);
    expect(find.textContaining('more ordinance'), findsNothing);
  });

  testWidgets('two ordinances show the first and "+1 more ordinance"', (
    tester,
  ) async {
    await show(tester, ticket(ordinances: ['Ordinance one', 'Ordinance two']));
    expect(find.text('Ordinance one'), findsOneWidget);
    expect(find.text('Ordinance two'), findsNothing);
    expect(find.text('+1 more ordinance'), findsOneWidget);
  });

  testWidgets('five ordinances show one and "+4 more ordinances"', (
    tester,
  ) async {
    await show(
      tester,
      ticket(ordinances: ['One', 'Two', 'Three', 'Four', 'Five']),
    );
    expect(find.text('One'), findsOneWidget);
    expect(find.text('Two'), findsNothing);
    expect(find.text('+4 more ordinances'), findsOneWidget);
  });

  testWidgets('a very long ordinance is cut at two lines', (tester) async {
    final long = List.filled(60, 'cleanliness').join(' ');
    await show(tester, ticket(ordinances: [long]));
    final text = tester.widget<Text>(find.text(long));
    expect(text.maxLines, 2);
    expect(text.overflow, TextOverflow.ellipsis);
  });

  testWidgets('View Details sits under the date and spans the card width', (
    tester,
  ) async {
    await show(tester, ticket(stall: '12'));
    final date = tester.getRect(find.byIcon(Icons.calendar_today_outlined));
    final button = tester.getRect(find.byType(FilledButton));
    final card = tester.getRect(find.byType(InspectionCard));
    expect(button.top, greaterThanOrEqualTo(date.bottom));
    expect(button.left, card.left + 20);
    expect(button.right, card.right - 20);
    expect(find.text('View Details'), findsOneWidget);
  });

  testWidgets('narrow phone with huge text does not overflow', (tester) async {
    await show(tester, ticket(stall: '12'), width: 280, textScale: 1.6);
    expect(tester.takeException(), isNull);
    expect(find.text('View Details'), findsOneWidget);
  });

  testWidgets('tapping View Details opens the ticket details', (tester) async {
    await show(tester, ticket(stall: '12'));
    await tester.tap(find.text('View Details'));
    await tester.pumpAndSettle();
    expect(find.text('details opened'), findsOneWidget);
  });

  testWidgets('View Details is hidden until the card is tapped', (
    tester,
  ) async {
    await show(tester, ticket(stall: '12'), expanded: false);
    expect(find.text('View Details'), findsNothing);
    await tester.tap(find.text('Market Goods'));
    await tester.pumpAndSettle();
    expect(find.text('View Details'), findsOneWidget);
    expect(find.text('details opened'), findsNothing);
    await tester.tap(find.text('Market Goods'));
    await tester.pumpAndSettle();
    expect(find.text('View Details'), findsNothing);
  });

  testWidgets('a ticket card shows no control number or issue place', (
    tester,
  ) async {
    await show(tester, ticket(stall: '12'));
    expect(find.textContaining('Control number'), findsNothing);
    expect(find.textContaining('Issue place'), findsNothing);
  });

  testWidgets('a warning card shows the person name with no label', (
    tester,
  ) async {
    await show(tester, warning());
    expect(find.text('Maria Santos'), findsOneWidget);
    expect(find.textContaining('Confirmed person'), findsNothing);
  });

  testWidgets('the card shrinks while pressed and returns on release', (
    tester,
  ) async {
    await show(tester, ticket(stall: '12'), expanded: false);
    double scale() =>
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;
    expect(scale(), 1);
    final press = await tester.startGesture(
      tester.getCenter(find.text('Market Goods')),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(scale(), AppTheme.inspectionCardPressedScale);
    await press.up();
    await tester.pumpAndSettle();
    expect(scale(), 1);
  });
}
