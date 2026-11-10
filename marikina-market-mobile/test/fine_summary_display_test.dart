import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/fine_summary_model.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/fine_summary.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ordinance.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/ordinance_category.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/fine_summary_section.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/preview/penalty_details_section.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/preview/violation_details_section.dart';

// Criterion 4: the offense position and fine shown after the person and the
// ordinances are chosen, on the entry page and again on the Review page.
// Expected values are worked out by hand from the lines below:
//   Sec. 12 is this person's 2nd offense, fixed fine 500.00
//   Sec. 49 is this person's 3rd offense, fixed fine 1,500.00
//   total = 500.00 + 1,500.00 = 2,000.00

Map<String, Object?> line(
  int id,
  String section,
  int offense, {
  double? amount,
  String kind = 'Fixed',
  String? severity = 'Minor',
}) => {
  'ordinance_id': id,
  'ordinance_no': '011',
  'section': section,
  'payment_amount': amount,
  'severity': severity,
  'offense_number': offense,
  'is_duplicate': false,
  'fine_kind': kind,
};

// The same steps the entry page takes: server reply, then local totals.
FineSummary summaryOf(List<Map<String, Object?>> lines, {double? total}) =>
    FineSummaryModel.fromJson({
      'total_payment_amount': total,
      'highest_severity': 'Minor',
      'breakdown': lines,
    }).toEntity().withAssessments({});

Ordinance ordinance(int id, String section, String title) => Ordinance(
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
  penaltyTierCount: 3,
);

final stall = ordinance(12, '12', 'Unsanitary stall');
final attire = ordinance(49, '49', 'Improper attire');

final secondAndThird = summaryOf([
  line(12, '12', 2, amount: 500),
  line(49, '49', 3, amount: 1500),
], total: 2000);

Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

void main() {
  testWidgets(
    'entry page shows each offense position, its fine and the total',
    (tester) async {
      await pump(
        tester,
        FineSummarySection(
          items: [stall, attire],
          fineSummary: secondAndThird,
          isTicket: true,
          onDelete: (_) {},
        ),
      );
      expect(find.text('2nd offense'), findsOneWidget);
      expect(find.text('3rd offense'), findsOneWidget);
      expect(find.text('₱500.00'), findsOneWidget);
      expect(find.text('₱1,500.00'), findsOneWidget);
      expect(find.text('₱2,000.00'), findsOneWidget);
    },
  );

  testWidgets('Review page shows the same positions, fines and total', (
    tester,
  ) async {
    await pump(
      tester,
      Column(
        children: [
          ViolationDetailsSection(
            fine: secondAndThird,
            ordinances: [stall, attire],
            isTicket: true,
            penaltyType: PenaltyType.cashFine,
            marketSection: 'Section A',
            description: 'Reviewed paper citation',
          ),
          PenaltyDetailsSection(
            severity: secondAndThird.severity,
            penaltyType: PenaltyType.cashFine,
            totalFineAmount: secondAndThird.totalPaymentAmount,
            communityHrs: null,
          ),
        ],
      ),
    );
    expect(find.text('2nd offense'), findsOneWidget);
    expect(find.text('3rd offense'), findsOneWidget);
    expect(find.text('₱500.00'), findsOneWidget);
    expect(find.text('₱1,500.00'), findsOneWidget);
    expect(find.text('₱2,000.00'), findsOneWidget);
  });

  testWidgets('a line with no confirmed penalty makes the total unavailable, '
      'never a partial total or zero', (tester) async {
    final partial = summaryOf([
      line(12, '12', 2, amount: 500),
      line(49, '49', 3, kind: 'Unconfirmed'),
    ]);
    await pump(
      tester,
      FineSummarySection(
        items: [stall, attire],
        fineSummary: partial,
        isTicket: true,
        onDelete: (_) {},
      ),
    );
    expect(find.text('3rd offense'), findsOneWidget);
    expect(
      find.text('Unavailable — the penalty is not confirmed'),
      findsOneWidget,
    );
    expect(find.text('₱500.00'), findsOneWidget, reason: 'the confirmed line');
    expect(find.text('₱0.00'), findsNothing);
    expect(find.text('Assessment required'), findsOneWidget);
  });

  testWidgets('a missing scoring severity is not shown as a fine or as Minor', (
    tester,
  ) async {
    final unscored = summaryOf([
      line(12, '12', 1, amount: 500, severity: null),
    ]);
    await pump(
      tester,
      FineSummarySection(
        items: [stall],
        fineSummary: unscored,
        isTicket: true,
        onDelete: (_) {},
      ),
    );
    expect(
      find.text('Unavailable — an administrator must set the scoring severity'),
      findsOneWidget,
    );
    expect(find.text('₱0.00'), findsNothing);
  });
}
