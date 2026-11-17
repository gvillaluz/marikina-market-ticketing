import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/connectivity/cubit/connectivity_cubit.dart';
import 'package:marikina_market_mobile/core/router/route_args.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/utils/password_change_check.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:marikina_market_mobile/features/auth/presentation/widgets/change_password_card.dart'
    as forced;
import 'package:marikina_market_mobile/features/password_recovery/presentation/bloc/password_recovery_bloc.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/pages/reset_password_page.dart';

import '../auth/login_mobile_flow_test.dart' show loginBloc;
import '../auth/login_test_network_info.dart';
import 'reset_password_flow_test.dart' show Server, succeeds;

const labels = ['At least 8 characters', 'A number', 'A capital letter'];

/// The checklist line for [label], as a screen reader would announce it.
Finder ruleLine(String label, {required bool met}) =>
    find.bySemanticsLabel('${met ? 'Done' : 'Not yet'}: $label');

/// Checks every line: only the labels in [metLabels] show as done.
void expectMet(Set<String> metLabels) {
  for (final label in labels) {
    final met = metLabels.contains(label);
    expect(ruleLine(label, met: met), findsOneWidget, reason: label);
    expect(ruleLine(label, met: !met), findsNothing, reason: label);
  }
}

Future<void> pumpForcedScreen(WidgetTester tester) async {
  late ConnectivityCubit connectivity;
  late AuthBloc auth;
  await tester.runAsync(() async {
    connectivity = ConnectivityCubit(LoginTestNetworkInfo());
    auth = loginBloc(
      connectivity,
      (options) async => throw StateError('nothing should be sent'),
    );
    await auth.stream
        .firstWhere((s) => s is Unauthenticated)
        .timeout(const Duration(seconds: 5));
  });
  addTearDown(connectivity.close);
  addTearDown(auth.close);
  await tester.pumpWidget(
    BlocProvider<AuthBloc>.value(
      value: auth,
      child: MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: SingleChildScrollView(child: forced.ChangePasswordCard()),
        ),
      ),
    ),
  );
}

Future<void> pumpResetScreen(WidgetTester tester) async {
  final server = Server(succeeds);
  late PasswordRecoveryBloc bloc;
  await tester.runAsync(() async => bloc = server.bloc());
  addTearDown(() => unawaited(bloc.close()));
  await tester.pumpWidget(
    BlocProvider.value(
      value: bloc,
      child: MaterialApp(
        theme: AppTheme.light,
        home: ResetPasswordPage(
          args: ResetPasswordArgs(
            username: 'vendor01',
            resetToken: 'synthetic-reset',
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('the three rules', () {
    test('are listed in order with plain labels', () {
      expect(PasswordChangeCheck.rules.map((rule) => rule.label), labels);
    });

    // Each row: typed password, then whether it meets each rule in order.
    const cases = <String, List<bool>>{
      '': [false, false, false],
      'abcdefgh': [true, false, false],
      'abc1': [false, true, false],
      'Abc': [false, false, true],
      'abcdefg1': [true, true, false],
      'Abcdefg1': [true, true, true],
      '1234567A': [true, true, true],
    };
    for (final MapEntry(key: typed, value: expected) in cases.entries) {
      test('"$typed" meets $expected', () {
        expect(
          PasswordChangeCheck.rules.map((rule) => rule.met(typed)),
          expected,
        );
      });
    }

    test('the error appears exactly when a rule is not met', () {
      const message =
          'Use at least 8 characters, with a number and a capital letter.';
      for (final MapEntry(key: typed, value: expected) in cases.entries) {
        expect(
          PasswordChangeCheck.newPasswordProblem(typed),
          expected.every((met) => met) ? isNull : message,
          reason: typed,
        );
      }
    });
  });

  for (final (name, pump, newPasswordBox) in [
    ('change password (temporary password)', pumpForcedScreen, 1),
    ('create a new password (forgot password)', pumpResetScreen, 0),
  ]) {
    group(name, () {
      testWidgets('shows the checklist instead of the grey sentence', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await pump(tester);
        expectMet({});
        expect(find.text(PasswordChangeCheck.hint), findsNothing);
        semantics.dispose();
      });

      testWidgets('ticks the rules met as you type', (tester) async {
        final semantics = tester.ensureSemantics();
        await pump(tester);
        final box = find.byType(TextField).at(newPasswordBox);

        await tester.enterText(box, 'abc1');
        await tester.pumpAndSettle();
        expectMet({'A number'});

        await tester.enterText(box, 'abcdefg1');
        await tester.pumpAndSettle();
        expectMet({'At least 8 characters', 'A number'});

        await tester.enterText(box, 'Abcdefg1');
        await tester.pumpAndSettle();
        expectMet(labels.toSet());

        await tester.enterText(box, 'Abc');
        await tester.pumpAndSettle();
        expectMet({'A capital letter'});
        semantics.dispose();
      });

      testWidgets('fits a narrow phone with large text', (tester) async {
        tester.view.physicalSize = const Size(320, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pump(tester);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        for (final label in labels) {
          expect(find.text(label), findsOneWidget);
        }
      });
    });
  }
}
