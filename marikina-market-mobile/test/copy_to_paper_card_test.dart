import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ordinance.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/ordinance_category.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/copy_to_paper_card.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/ticket_paper_field.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/ticket_paper_field_group.dart';

Ordinance ordinance(int id, String? section, String title) => Ordinance(
  id: id,
  ordinanceNo: '011',
  series: '2014',
  section: section,
  title: title,
  description: '',
  category: OrdinanceCategory.sanitation,
  severity: null,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
  isActive: true,
  penaltyTierCount: 1,
);

final stall = ordinance(12, '12', 'Unsanitary stall');
final attire = ordinance(49, '49', 'Improper attire');

Future<void> pumpCard(
  WidgetTester tester, {
  bool isTicket = true,
  String name = 'Juan Dela Cruz',
  String address = '31 Synthetic Market Lane',
  String place = 'Section A, Stall A-12',
  List<Ordinance>? ordinances,
  PenaltyType penaltyType = PenaltyType.cashFine,
  double? fineTotal = 1000,
  int? communityHours,
}) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: SingleChildScrollView(
        child: CopyToPaperCard(
          isTicket: isTicket,
          name: name,
          address: address,
          place: place,
          officerName: 'Pedro Reyes',
          ordinances: ordinances ?? [stall],
          penaltyType: penaltyType,
          fineTotal: fineTotal,
          communityHours: communityHours,
          now: DateTime(2026, 11, 7, 9, 5),
        ),
      ),
    ),
  ),
);

// Every paper line the card lists, in the order it shows them.
List<TicketPaperField> paperFields(WidgetTester tester) => [
  for (final group in tester.widgetList<TicketPaperFieldGroup>(
    find.byType(TicketPaperFieldGroup),
  ))
    ...group.fields,
];

// The value shown next to a paper label on the card.
String? valueOf(WidgetTester tester, String label) {
  final fields = paperFields(tester).where((field) => field.label == label);
  return fields.isEmpty ? null : fields.single.value;
}

void main() {
  testWidgets('ticket card shows the paper ticket fields in paper order', (
    tester,
  ) async {
    await pumpCard(tester);

    expect(find.text('Copy to paper ticket'), findsOneWidget);
    expect(paperFields(tester).map((field) => field.label), [
      'NAME:',
      'ADDRESS:',
      'ORDINANCE:',
      'FINE/PENALTIES:',
      'PLACE:',
      'DATE / TIME:',
      'NAME & SIGNATURE OF APPREHENDING OFFICER:',
    ]);
    expect(valueOf(tester, 'NAME:'), 'Juan Dela Cruz');
    expect(valueOf(tester, 'ADDRESS:'), '31 Synthetic Market Lane');
    expect(
      valueOf(tester, 'ORDINANCE:'),
      '011 series of 2014, Sec. 12\nUnsanitary stall',
    );
    expect(valueOf(tester, 'FINE/PENALTIES:'), 'Php 1,000.00');
    expect(valueOf(tester, 'PLACE:'), 'Section A, Stall A-12');
    expect(valueOf(tester, 'DATE / TIME:'), '9:05 AM 11/7/2026');
    expect(
      valueOf(tester, 'NAME & SIGNATURE OF APPREHENDING OFFICER:'),
      'Pedro Reyes',
    );
  });

  testWidgets('fine/penalties shows only the value to write', (tester) async {
    final cases = <(PenaltyType, double?, int?), String>{
      (PenaltyType.cashFine, 1500, null): 'Php 1,500.00',
      (PenaltyType.cashFine, 1000, null): 'Php 1,000.00',
      (PenaltyType.cashFine, 500, null): 'Php 500.00',
      (PenaltyType.cashFine, 2500.5, null): 'Php 2,500.50',
      (PenaltyType.bloodDonation, 500, null): 'Blood Donation',
      (PenaltyType.communityService, 500, 4): 'Community Service, 4 hrs',
    };
    for (final MapEntry(key: (penalty, total, hours), value: expected)
        in cases.entries) {
      await pumpCard(
        tester,
        penaltyType: penalty,
        fineTotal: total,
        communityHours: hours,
      );
      expect(valueOf(tester, 'FINE/PENALTIES:'), expected);
    }
  });

  testWidgets('several ordinances are listed in the chosen order', (
    tester,
  ) async {
    await pumpCard(
      tester,
      ordinances: [attire, stall, ordinance(53, null, 'Use of sidewalks')],
    );
    expect(
      valueOf(tester, 'ORDINANCE:'),
      '011 series of 2014, Sec. 49\nImproper attire\n'
      '011 series of 2014, Sec. 12\nUnsanitary stall\n'
      '011 series of 2014\nUse of sidewalks',
    );
  });

  testWidgets('the card follows changes to the page', (tester) async {
    await pumpCard(tester, ordinances: [stall, attire]);
    await pumpCard(
      tester,
      ordinances: [attire],
      penaltyType: PenaltyType.bloodDonation,
      place: 'Fish aisle near F-014',
    );
    expect(
      valueOf(tester, 'ORDINANCE:'),
      '011 series of 2014, Sec. 49\nImproper attire',
    );
    expect(valueOf(tester, 'FINE/PENALTIES:'), 'Blood Donation');
    expect(valueOf(tester, 'PLACE:'), 'Fish aisle near F-014');
  });

  testWidgets('the card stays hidden until everything it lists is ready', (
    tester,
  ) async {
    final notReady = <String, Future<void> Function()>{
      'no ordinance': () => pumpCard(tester, ordinances: []),
      'fine not complete': () => pumpCard(tester, fineTotal: null),
      'community service hours missing': () => pumpCard(
        tester,
        penaltyType: PenaltyType.communityService,
        communityHours: null,
      ),
      'community service under 3 hours': () => pumpCard(
        tester,
        penaltyType: PenaltyType.communityService,
        communityHours: 2,
      ),
      'no name': () => pumpCard(tester, name: ''),
      'no address on a ticket': () => pumpCard(tester, address: ''),
      'blank place': () => pumpCard(tester, place: '  '),
      'warning without a place': () =>
          pumpCard(tester, isTicket: false, place: ''),
    };
    for (final MapEntry(key: reason, value: pump) in notReady.entries) {
      await pump();
      expect(find.byType(TicketPaperFieldGroup), findsNothing, reason: reason);
      expect(
        find.textContaining('Copy to paper'),
        findsNothing,
        reason: reason,
      );
    }

    await pumpCard(
      tester,
      penaltyType: PenaltyType.communityService,
      communityHours: 3,
    );
    expect(valueOf(tester, 'FINE/PENALTIES:'), 'Community Service, 3 hrs');
  });

  testWidgets('warning card shows the BABALA fields and no fine', (
    tester,
  ) async {
    await pumpCard(
      tester,
      isTicket: false,
      name: 'Maria Santos',
      address: '',
      ordinances: [attire, stall],
      fineTotal: null,
    );

    expect(find.text('Copy to paper warning'), findsOneWidget);
    expect(paperFields(tester).map((field) => field.label), [
      'Petsa:',
      'Pangalan:',
      'Lugar:',
      'Ordinansa Blg.:',
      'Ordinansa Blg.:',
      'Market Enforcer:',
    ]);
    expect(valueOf(tester, 'Petsa:'), '11/7/2026');
    expect(valueOf(tester, 'Pangalan:'), 'Maria Santos');
    expect(valueOf(tester, 'Lugar:'), 'Section A, Stall A-12');
    expect(
      paperFields(tester)
          .where((field) => field.label == 'Ordinansa Blg.:')
          .map((field) => field.value),
      [
        '011, Serye: 2014, Sec. 49\nImproper attire',
        '011, Serye: 2014, Sec. 12\nUnsanitary stall',
      ],
    );
    expect(valueOf(tester, 'Market Enforcer:'), 'Pedro Reyes');
  });

  for (final width in [320.0, 360.0]) {
    for (final isTicket in [true, false]) {
      testWidgets(
        '${isTicket ? 'ticket' : 'warning'} card fits $width px with large text',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = 2;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await pumpCard(
            tester,
            isTicket: isTicket,
            ordinances: [
              ordinance(
                53,
                '53',
                'Restriction for use of streets, sidewalks and public places',
              ),
            ],
            fineTotal: 1500,
          );
          expect(find.byType(TicketPaperFieldGroup), findsWidgets);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
