import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/payment_type_section.dart';

void main() {
  testWidgets('disabled independent alternatives cannot be selected', (
    tester,
  ) async {
    final hoursController = TextEditingController();
    PenaltyType? changedType;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PaymentTypeSection(
            selectedPenaltyType: PenaltyType.bloodDonation,
            allowBloodDonation: false,
            allowCommunityService: false,
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
    expect(find.text('Payment method'), findsOneWidget);
    hoursController.dispose();
  });

  testWidgets(
    'blood donation can be enabled independently of community service',
    (tester) async {
      final hoursController = TextEditingController();
      PenaltyType? changedType;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentTypeSection(
              selectedPenaltyType: PenaltyType.cashFine,
              allowBloodDonation: true,
              allowCommunityService: false,
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
      changedType = null;
      await tester.tap(find.text('Community service'));
      await tester.pump();
      expect(changedType, isNull);
      hoursController.dispose();
    },
  );

  Future<void> show(
    WidgetTester tester, {
    bool allowCashFine = true,
    ValueChanged<PenaltyType>? onChangeType,
  }) async {
    final hours = TextEditingController();
    addTearDown(hours.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: PaymentTypeSection(
            selectedPenaltyType: PenaltyType.communityService,
            allowCashFine: allowCashFine,
            allowBloodDonation: false,
            allowCommunityService: true,
            totalFineAmount: null,
            onChangeType: onChangeType ?? (_) {},
            communityHrsController: hours,
            communityHrsError: null,
          ),
        ),
      ),
    );
  }

  testWidgets('cash can be greyed out for changing a penalty', (tester) async {
    PenaltyType? changed;
    await show(
      tester,
      allowCashFine: false,
      onChangeType: (value) => changed = value,
    );

    await tester.tap(find.text('Cash fine — not available for this ticket'));
    await tester.pump();

    expect(changed, isNull);
    expect(find.text('Cash fine — assessment required'), findsNothing);
  });

  testWidgets('cash without an amount can still be chosen when issuing', (
    tester,
  ) async {
    PenaltyType? changed;
    await show(tester, onChangeType: (value) => changed = value);

    await tester.tap(find.text('Cash fine — assessment required'));
    await tester.pump();

    expect(changed, PenaltyType.cashFine);
  });

  testWidgets('hours use a number keypad and a box at least 48 tall', (
    tester,
  ) async {
    await show(tester);

    final field = find.byType(TextField);
    expect(tester.widget<TextField>(field).keyboardType, TextInputType.number);
    expect(tester.getSize(field).height, greaterThanOrEqualTo(48));
  });

  testWidgets('hint and greyed rows read at least 4.5 to 1', (tester) async {
    await show(tester);

    double contrast(Color text, Color background) =>
        (background.computeLuminance() + 0.05) /
        (text.computeLuminance() + 0.05);
    final hint = tester.widget<Text>(find.text('hours(minimum of 3 hours)'));
    final greyed = find.text('Blood donation');
    final greyedColor = tester.widget<Text>(greyed).style!.color!;

    expect(
      contrast(hint.style!.color!, Colors.white),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrast(greyedColor, AppTheme.ticketDetailBackground),
      greaterThanOrEqualTo(4.5),
    );
    expect(greyedColor, isNot(AppColors.primaryBlack));
    expect(
      find.ancestor(of: greyed, matching: find.byType(Opacity)),
      findsNothing,
    );
  });
}
