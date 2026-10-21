import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/severity.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/payment_type_section.dart';

void main() {
  testWidgets('high severity only allows cash fine', (tester) async {
    final hoursController = TextEditingController();
    PenaltyType? changedType;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PaymentTypeSection(
            selectedPenaltyType: PenaltyType.bloodDonation,
            severity: Severity.high,
            totalFineAmount: 100,
            onChangeType: (value) => changedType = value,
            communityHrsController: hoursController,
            communityHrsError: null,
          ),
        ),
      ),
    );

    expect(find.text('hours(minimum of 3 hours)'), findsNothing);
    await tester.tap(find.text('Blood donation'));
    await tester.tap(find.text('Community service'));
    await tester.pump();

    expect(changedType, isNull);
    expect(find.text('How the violator pays'), findsOneWidget);
    hoursController.dispose();
  });

  testWidgets('non-high severity allows other penalty types', (tester) async {
    final hoursController = TextEditingController();
    PenaltyType? changedType;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PaymentTypeSection(
            selectedPenaltyType: PenaltyType.cashFine,
            severity: Severity.moderate,
            totalFineAmount: 100,
            onChangeType: (value) => changedType = value,
            communityHrsController: hoursController,
            communityHrsError: null,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Blood donation'));
    await tester.pump();

    expect(changedType, PenaltyType.bloodDonation);
    hoursController.dispose();
  });
}
