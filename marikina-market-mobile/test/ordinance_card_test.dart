import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_model.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ordinance.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/bottom_sheets/ordinance_card.dart';

import 'features/tickets/data/models/ordinance_model_test.dart'
    show ordinanceResponse;

// The ordinance card in the "Select ordinances" sheet. Expected texts are
// worked out by hand from the values below.

Ordinance ordinance([Map<String, Object?> changes = const {}]) =>
    OrdinanceModel.fromJson({
      ...ordinanceResponse,
      'ordinance_no': '145',
      'series': '2006',
      ...changes,
    }).toEntity();

Future<void> showCard(
  WidgetTester tester, {
  Ordinance? item,
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
          body: OrdinanceCard(
            ordinance: item ?? ordinance(),
            query: query,
            isSelected: isSelected,
            onTap: onTap,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the number, section, category and title separately', (
    tester,
  ) async {
    await showCard(tester);
    expect(find.text('Ord No. 145, Series of 2006'), findsOneWidget);
    expect(find.text('Section 69'), findsOneWidget);
    expect(find.text('Sanitation'), findsOneWidget);
    expect(find.text('Proper Waste Disposal'), findsOneWidget);
  });

  testWidgets('names the specific category of an Others ordinance', (
    tester,
  ) async {
    await showCard(
      tester,
      item: ordinance({
        'category': 'Others',
        'specific_category': 'Market clearance and stall requirements',
      }),
    );
    expect(
      find.text('Others: Market clearance and stall requirements'),
      findsOneWidget,
    );
  });

  testWidgets('an ordinance without a section says so', (tester) async {
    await showCard(tester, item: ordinance({'section': null}));
    expect(find.text('Section unavailable'), findsOneWidget);
  });

  testWidgets('bolds the typed text in the number and in the title', (
    tester,
  ) async {
    await showCard(tester, query: '145');
    final number = tester.widget<Text>(
      find.text('Ord No. 145, Series of 2006'),
    );
    final parts = (number.textSpan! as TextSpan).children!.cast<TextSpan>();
    expect(parts.map((part) => part.text), [
      'Ord No. ',
      '145',
      ', Series of 2006',
    ]);
    expect(parts[1].style?.fontWeight, FontWeight.w800);

    await showCard(tester, query: 'waste');
    final title = tester.widget<Text>(find.text('Proper Waste Disposal'));
    final words = (title.textSpan! as TextSpan).children!.cast<TextSpan>();
    expect(words.map((part) => part.text), ['Proper ', 'Waste', ' Disposal']);
    expect(words[1].style?.fontWeight, FontWeight.w800);
  });

  testWidgets('tapping the card calls onTap', (tester) async {
    var taps = 0;
    await showCard(tester, onTap: () => taps++);
    await tester.tap(find.byType(OrdinanceCard));
    expect(taps, 1);
  });

  testWidgets('a card with no onTap ignores taps and reads as disabled', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await showCard(tester);
    await tester.tap(find.byType(OrdinanceCard));
    expect(tester.takeException(), isNull);
    expect(
      tester.getSemantics(
        find.descendant(
          of: find.byType(OrdinanceCard),
          matching: find.byType(MergeSemantics),
        ),
      ),
      isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
    );
    semantics.dispose();
  });

  testWidgets('a selected card shows a filled check and says it is selected', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await showCard(tester, isSelected: true, onTap: () {});
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(
      tester.getSemantics(
        find.descendant(
          of: find.byType(OrdinanceCard),
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
      await showCard(
        tester,
        width: 280,
        textScale: scale,
        item: ordinance({
          'category': 'Others',
          'specific_category': 'Market clearance and stall requirements',
        }),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Proper Waste Disposal'), findsOneWidget);
    });
  }
}
