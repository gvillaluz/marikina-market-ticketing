import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/auth_error_notice.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:marikina_market_mobile/features/auth/presentation/widgets/change_password_card.dart';
import 'package:marikina_market_mobile/features/auth/presentation/widgets/login_otp_card.dart';
import 'package:pinput/pinput.dart';

import '../../core/login_frame_test.dart' show withLogin;
import 'data/login_mobile_contract_test.dart'
    show otpResponse, profileResponse, reply, tokenResponse;
import 'login_screens_look_test.dart' show subtitle, withMustChangeLogin;

/// How far apart two colours are in brightness, as the readability
/// guideline measures it (1 = the same, 21 = black on white).
double contrast(Color a, Color b) {
  final lighter = a.computeLuminance() > b.computeLuminance() ? a : b;
  final darker = identical(lighter, a) ? b : a;
  return (lighter.computeLuminance() + 0.05) /
      (darker.computeLuminance() + 0.05);
}

/// What a screen reader would say for each text box, in screen order.
List<String> boxNames(WidgetTester tester) => [
  for (final box in find.byType(EditableText).evaluate())
    tester.getSemantics(find.byWidget(box.widget)).label,
];

DioException refused(RequestOptions options) => DioException(
  requestOptions: options,
  type: DioExceptionType.badResponse,
  response: Response<Object?>(
    requestOptions: options,
    statusCode: 400,
    data: {'message': 'Incorrect username or password.'},
  ),
);

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('screen readers keep each box name after typing', () {
    testWidgets('log in boxes', (tester) async {
      final semantics = tester.ensureSemantics();
      await withLogin(tester, (router, bloc) async {
        await tester.enterText(find.byType(TextField).at(0), 'enforcer01');
        await tester.enterText(find.byType(TextField).at(1), 'ExamplePass1');
        await tester.pumpAndSettle();
        expect(boxNames(tester), ['Username', 'Password']);
      });
      semantics.dispose();
    });

    testWidgets('6-digit code boxes', (tester) async {
      final semantics = tester.ensureSemantics();
      await withMustChangeLogin(tester, (verify) async {
        await tester.enterText(find.byType(Pinput), '12');
        // The resend countdown keeps moving, so wait a set time instead.
        await tester.pump(const Duration(milliseconds: 500));
        // The typed digits may follow the name; the name must come first.
        final names = boxNames(tester);
        expect(names, hasLength(1));
        expect(names.single, startsWith('6-digit code'));
      });
      semantics.dispose();
    });

    testWidgets('change-password boxes', (tester) async {
      final semantics = tester.ensureSemantics();
      await withMustChangeLogin(tester, (verify) async {
        verify('001234');
        await tester.pumpAndSettle();
        expect(find.byType(ChangePasswordCard), findsOneWidget);
        for (var i = 0; i < 3; i++) {
          await tester.enterText(find.byType(TextField).at(i), 'Zz9abcdef$i');
        }
        await tester.pumpAndSettle();
        expect(boxNames(tester), [
          'Current password',
          'New password',
          'Confirm new password',
        ]);
      });
      semantics.dispose();
    });
  });

  group('text boxes are readable across the phone app', () {
    final theme = AppTheme.light.inputDecorationTheme;
    const fill = Colors.white;

    test('box outlines stand out at least 3 to 1', () {
      for (final border in [theme.border, theme.enabledBorder]) {
        final side = (border! as OutlineInputBorder).borderSide;
        expect(contrast(side.color, fill), greaterThanOrEqualTo(3));
        expect(
          contrast(side.color, AppTheme.light.scaffoldBackgroundColor),
          greaterThanOrEqualTo(3),
        );
      }
    });

    test('box icons stand out at least 3 to 1', () {
      for (final color in [theme.prefixIconColor, theme.suffixIconColor]) {
        expect(contrast(color!, fill), greaterThanOrEqualTo(3));
      }
    });

    test('grey hint text reads at least 4.5 to 1', () {
      expect(
        contrast(theme.hintStyle!.color!, fill),
        greaterThanOrEqualTo(4.5),
      );
    });

    testWidgets('6-digit code box outlines stand out at least 3 to 1', (
      tester,
    ) async {
      await withMustChangeLogin(tester, (verify) async {
        final box = tester.widget<Pinput>(find.byType(Pinput)).defaultPinTheme!;
        final border = box.decoration!.border! as Border;
        expect(contrast(border.top.color, fill), greaterThanOrEqualTo(3));
      });
    });

    testWidgets('the log in and change-password hints use the readable grey', (
      tester,
    ) async {
      final hint = theme.hintStyle!.color;
      Color? shown(String text) =>
          tester.widget<Text>(find.text(text)).style?.color;
      await withMustChangeLogin(tester, (verify) async {
        verify('001234');
        await tester.pumpAndSettle();
        expect(shown('Enter your current password'), hint);
        expect(shown('Enter your new password'), hint);
        expect(shown('Confirm your new password'), hint);
      });
    });

    testWidgets('the log in hints use the readable grey', (tester) async {
      final hint = theme.hintStyle!.color;
      await withLogin(tester, (router, bloc) async {
        for (final text in ['Enter your username', 'Enter your password']) {
          expect(tester.widget<Text>(find.text(text)).style?.color, hint);
        }
      });
    });
  });

  group('error messages sit under the heading, above the boxes', () {
    testWidgets('log in', (tester) async {
      await withLogin(
        tester,
        respond: (options) async => throw refused(options),
        (router, bloc) async {
          bloc.add(
            LoginSubmitted(username: 'enforcer01', password: 'WrongPass123'),
          );
          await tester.pumpAndSettle();
          final notice = tester.getRect(find.byType(AuthErrorNotice));
          expect(
            notice.top,
            greaterThan(tester.getRect(find.text(subtitle)).bottom),
          );
          expect(
            notice.bottom,
            lessThan(tester.getRect(find.byType(TextField).first).top),
          );
        },
      );
    });

    testWidgets('change password', (tester) async {
      await withLogin(
        tester,
        respond: (options) async => switch (options.path) {
          '/auth/verify-login-mobile' => reply(options, tokenResponse),
          '/user/me' => reply(options, {
            ...profileResponse,
            'mustChangedPassword': true,
          }),
          '/auth/mandatory-change-password' => throw refused(options),
          _ => reply(options, otpResponse),
        },
        (router, bloc) async {
          bloc.add(
            LoginSubmitted(username: 'enforcer01', password: 'ExamplePass123'),
          );
          await tester.pumpAndSettle();
          expect(find.byType(LoginOtpCard), findsOneWidget);
          bloc.add(VerifyLoginSubmitted('001234'));
          await tester.pumpAndSettle();
          expect(find.byType(ChangePasswordCard), findsOneWidget);
          final values = ['OldPass123!', 'NewPass123!', 'NewPass123!'];
          for (var i = 0; i < 3; i++) {
            await tester.enterText(find.byType(TextField).at(i), values[i]);
          }
          await tester.ensureVisible(find.text('Save password'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Save password'));
          await tester.pumpAndSettle();
          final notice = tester.getRect(find.byType(AuthErrorNotice));
          expect(
            notice.top,
            greaterThan(
              tester.getRect(find.textContaining('For your security')).bottom,
            ),
          );
          expect(
            notice.bottom,
            lessThan(tester.getRect(find.byType(TextField).first).top),
          );
        },
      );
    });
  });
}
