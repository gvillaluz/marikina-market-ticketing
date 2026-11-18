import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/widgets/recovery_step_counter.dart';

void main() {
  for (final step in [1, 2, 3, 4]) {
    testWidgets('step $step of 4 says so and fills that much of the bar', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: RecoveryStepCounter(step: step)),
        ),
      );
      expect(find.text('Step $step of 4'), findsOneWidget);
      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, step / 4);
    });
  }

  testWidgets('the bar is hidden from screen readers; the words carry it', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: RecoveryStepCounter(step: 3)),
      ),
    );
    final handle = tester.ensureSemantics();
    expect(find.bySemanticsLabel('Step 3 of 4'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('progress', caseSensitive: false)),
      findsNothing,
    );
    handle.dispose();
  });
}
