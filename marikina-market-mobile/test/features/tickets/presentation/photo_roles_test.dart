import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/ticket_detail_evidence_section.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ticket_detail_model.dart';
import 'business_snapshot_test.dart' show record;

void main() {
  testWidgets('legacy citation photos are explicitly unclassified', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TicketDetailEvidenceSection(
            evidences: ['https://example.test/legacy.jpg'],
            isTicket: true,
          ),
        ),
      ),
    );
    expect(find.text('Unclassified evidence'), findsOneWidget);
    expect(find.text('Paper ticket photo'), findsNothing);
    expect(find.text('Supporting evidence'), findsNothing);
  });
  testWidgets('saved paper and supporting groups use typed response items', (
    tester,
  ) async {
    final detail = TicketDetailModel.fromJson({
      ...record(null),
      'ticket_evidences': ['https://example.test/old-flat.jpg'],
      'evidence_items': [
        {
          'id': 1,
          'role': 'PaperTicket',
          'sort_order': 0,
          'url': 'https://example.test/paper.jpg',
        },
        {
          'id': 3,
          'role': 'Supporting',
          'sort_order': 1,
          'url': 'https://example.test/support-two.jpg',
        },
        {
          'id': 2,
          'role': 'Supporting',
          'sort_order': 0,
          'url': 'https://example.test/support-one.jpg',
        },
      ],
    }).toEntity();
    expect(detail.evidenceItems.map((item) => item.role), [
      'PaperTicket',
      'Supporting',
      'Supporting',
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TicketDetailEvidenceSection(
              evidences: detail.evidenceUrls!,
              evidenceItems: detail.evidenceItems,
              isTicket: true,
            ),
          ),
        ),
      ),
    );
    expect(find.text('Paper ticket photo'), findsOneWidget);
    expect(find.text('Supporting evidence'), findsOneWidget);
    expect(find.text('Unclassified evidence'), findsNothing);
    final groups = tester
        .widgetList<TicketDetailEvidenceSection>(
          find.byType(TicketDetailEvidenceSection),
        )
        .where((item) => !item.isTicket)
        .toList();
    expect(groups[0].evidences, ['https://example.test/paper.jpg']);
    expect(groups[1].evidences, [
      'https://example.test/support-one.jpg',
      'https://example.test/support-two.jpg',
    ]);
  });
  testWidgets('warnings do not acquire citation photo classification', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TicketDetailEvidenceSection(evidences: [], isTicket: false),
        ),
      ),
    );
    expect(find.text('Unclassified evidence'), findsNothing);
    expect(find.text('Paper ticket photo'), findsNothing);
    expect(find.text('Supporting evidence'), findsNothing);
  });
}
