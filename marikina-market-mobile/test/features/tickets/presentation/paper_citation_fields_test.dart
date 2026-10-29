import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/paper_citation_fields.dart';

void main() {
  testWidgets(
    'paper fields require reviewed values and preserve literal reference',
    (tester) async {
      final reference = TextEditingController();
      final place = TextEditingController();
      final form = GlobalKey<FormState>();
      addTearDown(reference.dispose);
      addTearDown(place.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Form(
              key: form,
              child: PaperCitationFields(
                referenceController: reference,
                placeController: place,
              ),
            ),
          ),
        ),
      );
      expect(form.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Paper reference is required.'), findsOneWidget);
      expect(find.text('Issue place is required.'), findsOneWidget);
      reference.text = '000456-a';
      place.text = 'Fish aisle near F-014';
      expect(form.currentState!.validate(), isTrue);
      expect(reference.text, '000456-a');
      reference.text = List.filled(201, '1').join();
      expect(form.currentState!.validate(), isFalse);
      reference.text = '000456';
      place.text = '   ';
      expect(form.currentState!.validate(), isFalse);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('paper fields wrap at 280px with enlarged text', (tester) async {
    tester.view.physicalSize = const Size(280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final reference = TextEditingController(text: '000456');
    final place = TextEditingController(text: 'Fish aisle near F-014');
    addTearDown(reference.dispose);
    addTearDown(place.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: AppTheme.inspectionCardPadding,
                child: Form(
                  child: PaperCitationFields(
                    referenceController: reference,
                    placeController: place,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Paper reference'), findsOneWidget);
    expect(find.text('Issue place'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
