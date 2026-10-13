import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/app_date_picker_dialog.dart';

void main() {
  testWidgets(
    'shared date modal lets the year change independently before confirmation',
    (tester) async {
      DateTime? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showDialog<DateTime>(
                    context: context,
                    builder: (_) => AppDatePickerDialog(
                      title: 'Date of birth',
                      initialDate: DateTime(1995, 6, 15),
                      firstDate: DateTime(1),
                      lastDate: DateTime(2026, 10, 13),
                    ),
                  );
                },
                child: const Text('Choose birth date'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Choose birth date'));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoDatePicker), findsOneWidget);
      expect(find.text('Date of birth'), findsOneWidget);
      expect(find.byType(ListWheelScrollView), findsNWidgets(3));
      await tester.drag(
        find.byType(ListWheelScrollView).last,
        const Offset(0, 180),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use this date'));
      await tester.pumpAndSettle();
      expect(result, isNotNull);
      expect(result!.year, lessThan(1995));
      expect(result!.month, 6);
      expect(result!.day, 15);
    },
  );

  testWidgets('cancel does not commit a changed date', (tester) async {
    DateTime? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showDialog<DateTime>(
                  context: context,
                  builder: (_) => AppDatePickerDialog(
                    initialDate: DateTime(1995, 6, 15),
                    firstDate: DateTime(1),
                    lastDate: DateTime(2026, 10, 13),
                  ),
                );
              },
              child: const Text('Choose birth date'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Choose birth date'));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byType(ListWheelScrollView).last,
      const Offset(0, 180),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets('shared date modal retains bounds and fits a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(280, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: AppDatePickerDialog(
              initialDate: DateTime(1995, 6, 15),
              firstDate: DateTime(1),
              lastDate: DateTime(2026, 10, 13),
            ),
          ),
        ),
      ),
    );
    final picker = tester.widget<CupertinoDatePicker>(
      find.byType(CupertinoDatePicker),
    );
    expect(picker.minimumDate, DateTime(1));
    expect(picker.maximumDate, DateTime(2026, 10, 13));
    expect(picker.dateOrder, DatePickerDateOrder.dmy);
    expect(find.text('Select date'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
