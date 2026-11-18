import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:marikina_market_mobile/core/router/route_args.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/auth_btn.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/otp_code_field.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/resend_code_button.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/reveal_message.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:marikina_market_mobile/features/auth/presentation/widgets/login_otp_card.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/bloc/password_recovery_bloc.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/bloc/password_recovery_state.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/pages/reset_password_page.dart';
import 'package:pinput/pinput.dart';

import '../features/password/reset_password_flow_test.dart'
    show Server, succeeds;

Widget screen(Widget child, {bool reduceMotion = false}) => MaterialApp(
  theme: AppTheme.light,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Scaffold(
      body: SingleChildScrollView(
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  ),
);

Color boxBorder(WidgetTester tester, int index) {
  final box = tester.widget<Container>(
    find.byKey(ValueKey('otp-success-box-$index')),
  );
  return (box.decoration! as BoxDecoration).border!.top.color;
}

void main() {
  group('button', () {
    Future<Size> sizeFor(
      WidgetTester tester, {
      bool loading = false,
      bool success = false,
    }) async {
      await tester.pumpWidget(
        screen(
          AuthBtn(
            label: 'Verify and log in',
            onPressed: () {},
            isLoading: loading,
            isSuccess: success,
          ),
        ),
      );
      // The waiting spinner never settles, so wait past every transition.
      await tester.pump(const Duration(milliseconds: 500));
      return tester.getSize(find.byType(ElevatedButton));
    }

    testWidgets('keeps its size when waiting and when showing the tick', (
      tester,
    ) async {
      final idle = await sizeFor(tester);
      expect(await sizeFor(tester, loading: true), idle);
      expect(await sizeFor(tester, success: true), idle);
    });

    testWidgets('the tick stays blue and cannot be pressed again', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        screen(
          AuthBtn(
            label: 'Verify',
            onPressed: () => taps++,
            isLoading: false,
            isSuccess: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.text('Verify'), findsNothing);
      expect(find.bySemanticsLabel('Done'), findsOneWidget);
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull, reason: 'disabled would turn grey');
      await tester.tap(find.byType(ElevatedButton));
      expect(taps, 0);
      semantics.dispose();
    });

    testWidgets('dips while pressed and comes back on release', (tester) async {
      await tester.pumpWidget(
        screen(AuthBtn(label: 'Log in', onPressed: () {}, isLoading: false)),
      );
      double scale() =>
          tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;
      expect(scale(), 1);
      final press = await tester.startGesture(
        tester.getCenter(find.byType(ElevatedButton)),
      );
      await tester.pump();
      expect(scale(), AppTheme.buttonPressScale);
      await press.up();
      await tester.pump();
      expect(scale(), 1);
    });

    testWidgets('does not dip while it is waiting', (tester) async {
      await tester.pumpWidget(
        screen(AuthBtn(label: 'Log in', onPressed: () {}, isLoading: true)),
      );
      final press = await tester.startGesture(
        tester.getCenter(find.byType(ElevatedButton)),
      );
      await tester.pump();
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
      await press.up();
    });

    testWidgets('with animations removed the tick appears at once', (
      tester,
    ) async {
      Widget button(bool success) => screen(
        AuthBtn(
          label: 'Log in',
          onPressed: () {},
          isLoading: false,
          isSuccess: success,
        ),
        reduceMotion: true,
      );
      await tester.pumpWidget(button(false));
      await tester.pumpWidget(button(true));
      await tester.pump();
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.text('Log in'), findsNothing);
      final fade = tester.widget<FadeTransition>(
        find
            .ancestor(
              of: find.byIcon(Icons.check),
              matching: find.byType(FadeTransition),
            )
            .first,
      );
      expect(fade.opacity.value, 1);
    });
  });

  group('code boxes', () {
    late TextEditingController code;
    setUp(() => code = TextEditingController(text: '123456'));
    tearDown(() => code.dispose());

    Widget field({
      bool enabled = true,
      bool wrong = false,
      bool verified = false,
      bool reduceMotion = false,
    }) => screen(
      OtpCodeField(
        controller: code,
        enabled: enabled,
        isWrong: wrong,
        isVerified: verified,
      ),
      reduceMotion: reduceMotion,
    );

    Pinput pinput(WidgetTester tester) =>
        tester.widget<Pinput>(find.byType(Pinput));

    double shakeOffset(WidgetTester tester) => tester
        .widget<Transform>(
          find.descendant(
            of: find.byType(OtpCodeField),
            matching: find.byKey(const ValueKey('otp-shake')),
          ),
        )
        .transform
        .getTranslation()
        .x;

    testWidgets('a wrong code shakes the row and turns it red', (tester) async {
      await tester.pumpWidget(field());
      expect(pinput(tester).forceErrorState, isFalse);
      await tester.pumpWidget(field(wrong: true));
      await tester.pump(const Duration(milliseconds: 40));
      expect(shakeOffset(tester), isNot(0));
      expect(pinput(tester).forceErrorState, isTrue);
      await tester.pumpAndSettle();
      expect(shakeOffset(tester), 0);
      expect(pinput(tester).forceErrorState, isTrue);
    });

    testWidgets('boxes stay centred and the green boxes sit on them', (
      tester,
    ) async {
      // Full width, as in the cards (a stretched column).
      Widget wide(bool verified) => screen(
        SizedBox(
          width: double.infinity,
          child: OtpCodeField(
            controller: code,
            enabled: false,
            isVerified: verified,
          ),
        ),
      );
      await tester.pumpWidget(wide(false));
      await tester.pumpWidget(wide(true));
      await tester.pumpAndSettle();
      expect(
        tester.getCenter(find.byType(Pinput)).dx,
        closeTo(tester.getCenter(find.byType(OtpCodeField)).dx, 0.5),
      );
      final firstBox = find
          .descendant(
            of: find.byType(Pinput),
            matching: find.byType(AnimatedContainer),
          )
          .first;
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('otp-success-box-0'))).dx,
        closeTo(tester.getTopLeft(firstBox).dx, 0.5),
      );
    });

    testWidgets('typing again clears the red', (tester) async {
      await tester.pumpWidget(field());
      await tester.pumpWidget(field(wrong: true));
      await tester.pumpAndSettle();
      code.text = '12345';
      await tester.pump();
      expect(pinput(tester).forceErrorState, isFalse);
    });

    testWidgets('locked boxes after a wrong code are still red', (
      tester,
    ) async {
      await tester.pumpWidget(field(enabled: false));
      await tester.pumpWidget(field(enabled: false, wrong: true));
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(OtpCodeField));
      final locked = pinput(tester).disabledPinTheme!.decoration!;
      expect(
        (locked.border! as Border).top.color,
        Theme.of(context).colorScheme.error,
      );
    });

    testWidgets('the right code turns the boxes green left to right', (
      tester,
    ) async {
      await tester.pumpWidget(field(enabled: false));
      expect(find.byKey(const ValueKey('otp-success-box-0')), findsNothing);
      await tester.pumpWidget(field(enabled: false, verified: true));
      // First box has started (it starts at 0 ms), the last starts at 200 ms.
      await tester.pump(const Duration(milliseconds: 60));
      expect(boxBorder(tester, 0).a, greaterThan(0));
      expect(boxBorder(tester, 5).a, 0);
      await tester.pumpAndSettle();
      for (var i = 0; i < 6; i++) {
        expect(boxBorder(tester, i), AppColors.primaryGreen);
      }
    });

    testWidgets('with animations removed: green at once and no shake', (
      tester,
    ) async {
      await tester.pumpWidget(field(enabled: false, reduceMotion: true));
      await tester.pumpWidget(
        field(enabled: false, verified: true, reduceMotion: true),
      );
      await tester.pump();
      for (var i = 0; i < 6; i++) {
        expect(boxBorder(tester, i), AppColors.primaryGreen);
      }
      await tester.pumpWidget(field(reduceMotion: true));
      await tester.pumpWidget(field(wrong: true, reduceMotion: true));
      await tester.pump();
      expect(shakeOffset(tester), 0);
      expect(pinput(tester).forceErrorState, isTrue);
    });
  });

  group('resend ring', () {
    Widget resend(
      int seconds, {
      bool sending = false,
      VoidCallback? onResend,
    }) => screen(
      ResendCodeButton(
        secondsLeft: seconds,
        isSending: sending,
        onResend: onResend ?? () {},
      ),
    );

    double ring(WidgetTester tester) => tester
        .widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        )
        .value!;

    testWidgets('fills as the wait runs down', (tester) async {
      await tester.pumpWidget(resend(30));
      await tester.pumpAndSettle();
      expect(ring(tester), 0);
      expect(find.text('Resend in 00:30'), findsOneWidget);
      await tester.pumpWidget(resend(15));
      await tester.pumpAndSettle();
      expect(ring(tester), closeTo(0.5, 0.001));
      expect(find.text('Resend in 00:15'), findsOneWidget);
      await tester.pumpWidget(resend(3));
      await tester.pumpAndSettle();
      expect(ring(tester), closeTo(0.9, 0.001));
    });

    testWidgets('when full, "Resend code" becomes an underlined link', (
      tester,
    ) async {
      var resends = 0;
      await tester.pumpWidget(resend(30, onResend: () => resends++));
      await tester.tap(find.byType(TextButton));
      expect(resends, 0);
      await tester.pumpWidget(resend(0, onResend: () => resends++));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      final link = tester.widget<Text>(find.text('Resend code'));
      expect(link.style!.decoration, TextDecoration.underline);
      await tester.tap(find.byType(TextButton));
      expect(resends, 1);
    });

    testWidgets(
      'on a 393-point-wide phone the countdown stays beside the question',
      (tester) async {
        // Real Roboto widths (the test font draws every letter as a square).
        await tester.runAsync(() async {
          final fonts =
              '${Platform.environment['FLUTTER_ROOT']}/bin/cache/'
              'artifacts/material_fonts';
          final loader = FontLoader('Roboto');
          for (final file in ['regular', 'medium', 'bold']) {
            loader.addFont(
              File(
                '$fonts/roboto-$file.ttf',
              ).readAsBytes().then(ByteData.sublistView),
            );
          }
          await loader.load();
        });
        // The test phone: 1080 x 2392 pixels at density 2.75.
        tester.view.physicalSize = const Size(1080, 2392);
        tester.view.devicePixelRatio = 2.75;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        // Same layout as LoginOtpPage.
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: AppTheme.authPagePadding,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppTheme.authMaxWidth,
                      ),
                      child: LoginOtpCard(
                        state: LoginOtpPending(
                          maskedEmail: 'm2-****@example.invalid',
                          resendCooldownSeconds: 24,
                          codeExpirySeconds: 600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final question = tester.getCenter(
          find.text('Didn’t receive the email?'),
        );
        final countdown = tester.getCenter(find.text('Resend in 00:24'));
        expect(countdown.dy, closeTo(question.dy, 2));
      },
    );

    testWidgets('a new wait after a resend starts the ring empty again', (
      tester,
    ) async {
      await tester.pumpWidget(resend(0));
      await tester.pumpWidget(resend(0, sending: true));
      expect(find.text('Sending code...'), findsOneWidget);
      await tester.pumpWidget(resend(60));
      await tester.pumpAndSettle();
      expect(ring(tester), 0);
      await tester.pumpWidget(resend(45));
      await tester.pumpAndSettle();
      expect(ring(tester), closeTo(0.25, 0.001));
    });
  });

  group('messages', () {
    Widget message(String? text, {bool reduceMotion = false}) => screen(
      RevealMessage(child: text == null ? null : Text(text)),
      reduceMotion: reduceMotion,
    );

    double height(WidgetTester tester) =>
        tester.getSize(find.byType(RevealMessage)).height;

    testWidgets('open and close smoothly', (tester) async {
      await tester.pumpWidget(message(null));
      expect(height(tester), 0);
      await tester.pumpWidget(message('User not found.'));
      await tester.pump(const Duration(milliseconds: 100));
      final opening = height(tester);
      await tester.pumpAndSettle();
      final open = height(tester);
      expect(opening, greaterThan(0));
      expect(opening, lessThan(open));
      await tester.pumpWidget(message(null));
      await tester.pump(const Duration(milliseconds: 60));
      expect(height(tester), greaterThan(0));
      expect(height(tester), lessThan(open));
      await tester.pumpAndSettle();
      expect(height(tester), 0);
    });

    testWidgets('with animations removed they appear at once', (tester) async {
      await tester.pumpWidget(message(null, reduceMotion: true));
      await tester.pumpWidget(message('User not found.', reduceMotion: true));
      await tester.pump();
      expect(find.text('User not found.'), findsOneWidget);
      final first = height(tester);
      expect(first, greaterThan(0));
      await tester.pumpAndSettle();
      expect(height(tester), first);
    });
  });

  group('last forgot-password step', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    Future<void> showReset(
      WidgetTester tester,
      PasswordRecoveryBloc bloc, {
      required bool reduceMotion,
    }) async {
      final router = GoRouter(
        initialLocation: '/reset',
        routes: [
          GoRoute(
            path: '/reset',
            builder: (context, state) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(disableAnimations: reduceMotion),
              child: ResetPasswordPage(
                args: ResetPasswordArgs(
                  username: 'vendor01',
                  resetToken: 'synthetic-reset',
                ),
              ),
            ),
          ),
          GoRoute(
            path: Routes.login,
            name: Routes.loginName,
            builder: (context, state) => const Text('login screen'),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.enterText(find.byType(TextField).at(0), 'NewPass123');
      await tester.enterText(find.byType(TextField).at(1), 'NewPass123');
      final submit = find.text('Change Password');
      await tester.ensureVisible(submit);
      await tester.runAsync(() async {
        final done = bloc.stream.firstWhere(
          (s) => s is ResetPasswordSuccessfully,
        );
        await tester.tap(submit);
        await done.timeout(const Duration(seconds: 5));
      });
      await tester.pump();
    }

    testWidgets('shows the tick for the hold, then opens log in', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late PasswordRecoveryBloc bloc;
      await tester.runAsync(() async => bloc = Server(succeeds).bloc());
      addTearDown(() => unawaited(bloc.close()));
      await showReset(tester, bloc, reduceMotion: false);
      await tester.pump(
        AppTheme.authSuccessHold - const Duration(milliseconds: 50),
      );
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.text('login screen'), findsNothing);
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pumpAndSettle();
      expect(find.text('login screen'), findsOneWidget);
    });

    testWidgets('with animations removed it opens log in straight away', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late PasswordRecoveryBloc bloc;
      await tester.runAsync(() async => bloc = Server(succeeds).bloc());
      addTearDown(() => unawaited(bloc.close()));
      await showReset(tester, bloc, reduceMotion: true);
      // Far less than the hold: only the frames needed to change screen.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(find.text('login screen'), findsOneWidget);
    });
  });
}
