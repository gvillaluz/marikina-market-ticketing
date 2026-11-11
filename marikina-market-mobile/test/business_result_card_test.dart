import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/vendor_summary.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/business_type.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/bottom_sheets/business_result_card.dart';

// The business result card in the "Find business" sheet. Synthetic business;
// expected texts are worked out by hand from the values below.

VendorSummary business({
  String? stallNumber = '12',
  BusinessType type = BusinessType.public,
}) => VendorSummary(
  id: 1,
  username: null,
  type: type,
  businessAccountNumber: 'ACC-100',
  stallNumber: stallNumber,
  tradeName: "Aling Nena's Store",
  lastName: 'Santos',
  firstName: 'Nena',
  middleName: null,
  address: '12, Shoe Ave, Sto. Niño, Marikina City',
  marketSectionId: 1,
  marketSectionName: 'Dry Goods',
);

Future<void> showCard(
  WidgetTester tester, {
  VendorSummary? vendor,
  String query = '',
  bool isSelected = false,
  VoidCallback? onTap,
  double width = 390,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: MediaQuery(
        data: MediaQueryData(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: Scaffold(
          body: BusinessResultCard(
            vendor: vendor ?? business(),
            query: query,
            isSelected: isSelected,
            onTap: onTap ?? () {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows each fact in its own place', (tester) async {
    await showCard(tester);
    expect(find.text("Aling Nena's Store"), findsOneWidget);
    expect(find.text('Stall 12'), findsOneWidget);
    expect(find.text('Dry Goods'), findsOneWidget);
    expect(find.text('Public'), findsOneWidget);
    expect(find.text('Nena Santos'), findsOneWidget);
    expect(find.text('12, Shoe Ave, Sto. Niño, Marikina City'), findsOneWidget);
    expect(find.text('Account ACC-100'), findsOneWidget);
  });

  testWidgets('shows a private business as Private', (tester) async {
    await showCard(tester, vendor: business(type: BusinessType.private));
    expect(find.text('Private'), findsOneWidget);
    expect(find.text('Public'), findsNothing);
  });

  testWidgets('a business without a stall number has no stall chip', (
    tester,
  ) async {
    await showCard(tester, vendor: business(stallNumber: null));
    expect(find.textContaining('Stall'), findsNothing);
    expect(find.textContaining('null'), findsNothing);
    expect(find.text('Dry Goods'), findsOneWidget);
  });

  testWidgets('bolds the typed text inside the name, ignoring capitals', (
    tester,
  ) async {
    await showCard(tester, query: 'nena');
    final name = tester.widget<Text>(find.text("Aling Nena's Store"));
    final parts = (name.textSpan! as TextSpan).children!.cast<TextSpan>();
    expect(parts.map((part) => part.text), ['Aling ', 'Nena', "'s Store"]);
    expect(parts[1].style?.fontWeight, FontWeight.w800);
    expect(parts[0].style, isNull);
    expect(parts[2].style, isNull);
  });

  testWidgets('bolds the typed text in the owner and address too', (
    tester,
  ) async {
    await showCard(tester, query: 'santos');
    final owner = tester.widget<Text>(find.text('Nena Santos'));
    final parts = (owner.textSpan! as TextSpan).children!.cast<TextSpan>();
    expect(parts.map((part) => part.text), ['Nena ', 'Santos']);
    expect(parts[1].style?.fontWeight, FontWeight.w800);
  });

  testWidgets('typed text with special characters is matched as plain text', (
    tester,
  ) async {
    await showCard(tester, query: '12, Shoe (');
    expect(tester.takeException(), isNull);
    expect(find.text("Aling Nena's Store"), findsOneWidget);
  });

  testWidgets('tapping the card calls onTap', (tester) async {
    var taps = 0;
    await showCard(tester, onTap: () => taps++);
    await tester.tap(find.byType(BusinessResultCard));
    expect(taps, 1);
  });

  testWidgets('a selected card shows a filled check and says it is selected', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await showCard(tester, isSelected: true);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(
      tester.getSemantics(
        find.descendant(
          of: find.byType(BusinessResultCard),
          matching: find.byType(MergeSemantics),
        ),
      ),
      isSemantics(isSelected: true, isButton: true),
    );
    semantics.dispose();
  });

  testWidgets('an unselected card shows an empty circle', (tester) async {
    await showCard(tester);
    expect(find.byIcon(Icons.check_circle), findsNothing);
    expect(find.byIcon(Icons.circle_outlined), findsOneWidget);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('fits a 280 wide screen at text scale $scale', (tester) async {
      await showCard(tester, width: 280, textScale: scale, query: 'nena');
      expect(tester.takeException(), isNull);
      expect(find.text('Account ACC-100'), findsOneWidget);
      expect(
        tester.getSize(find.byType(BusinessResultCard)).height,
        greaterThanOrEqualTo(48),
      );
    });
  }
}
