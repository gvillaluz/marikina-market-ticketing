import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/di/dependency_injection.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/auth_btn.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/login_frame.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/auth/presentation/widgets/change_password_card.dart';
import 'package:marikina_market_mobile/features/password_recovery/data/data_sources/password_recovery_remote_data_source.dart';
import 'package:marikina_market_mobile/features/password_recovery/data/repositories/password_recovery_repository_impl.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/use_cases/find_account_use_case.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/use_cases/reset_password_use_case.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/use_cases/send_otp_use_case.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/use_cases/verify_code_use_case.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/bloc/password_recovery_bloc.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/widgets/reset_password_fields.dart';
import 'package:pinput/pinput.dart';

import '../../core/login_frame_test.dart' show withLogin;
import 'data/login_mobile_contract_test.dart' show contractClient;
import 'login_screens_look_test.dart' show withMustChangeLogin;

const oldBandLine = 'Market inspections, tickets and records in one place.';
const newBandLine = 'For recording market inspections and tickets.';
const solidBoxIcons = [
  Icons.person_rounded,
  Icons.lock_rounded,
  Icons.visibility,
];

/// A form label as the website shows it: sentence case, bold navy.
void expectWebsiteLabel(WidgetTester tester, String text) {
  final style = tester.widget<Text>(find.text(text)).style;
  expect(style?.fontWeight, FontWeight.w600, reason: text);
  expect(style?.color, AppTheme.authVerificationTitleColor, reason: text);
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('log in screen', () {
    testWidgets('"Forgot password?" sits under the password box, on the '
        'right, above the Log in button, with a full-size tap area', (
      tester,
    ) async {
      await withLogin(tester, (router, bloc) async {
        final password = tester.getRect(find.byType(TextField).last);
        final forgot = tester.getRect(
          find.widgetWithText(TextButton, 'Forgot password?'),
        );
        final button = tester.getRect(find.byType(AuthBtn));
        expect(forgot.top, greaterThanOrEqualTo(password.bottom));
        expect(forgot.bottom, lessThanOrEqualTo(button.top));
        expect(forgot.right, closeTo(password.right, 1));
        expect(forgot.height, greaterThanOrEqualTo(48));
      });
    });

    testWidgets('the band says what the app is for', (tester) async {
      await withLogin(tester, (router, bloc) async {
        expect(find.text(newBandLine), findsOneWidget);
        expect(find.text(oldBandLine), findsNothing);
      });
    });

    testWidgets('labels are sentence case, bold navy', (tester) async {
      await withLogin(tester, (router, bloc) async {
        expect(find.text('USERNAME'), findsNothing);
        expect(find.text('PASSWORD'), findsNothing);
        expectWebsiteLabel(tester, 'Username');
        expectWebsiteLabel(tester, 'Password');
      });
    });

    testWidgets('box icons are all outline icons', (tester) async {
      await withLogin(tester, (router, bloc) async {
        for (final icon in solidBoxIcons) {
          expect(find.byIcon(icon), findsNothing);
        }
        expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
        expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
        expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      });
    });

    testWidgets('the page under the band is white', (tester) async {
      await withLogin(tester, (router, bloc) async {
        final page = tester.widget<Scaffold>(
          find.descendant(
            of: find.byType(LoginFrame),
            matching: find.byType(Scaffold),
          ),
        );
        expect(page.backgroundColor, Colors.white);
      });
    });
  });

  group('code screen', () {
    testWidgets('"Back to log in" is at the top, above the heading', (
      tester,
    ) async {
      await withMustChangeLogin(tester, (verify) async {
        final back = tester.getRect(find.text('Back to log in'));
        final heading = tester.getRect(find.text('Sign-in verification'));
        expect(back.bottom, lessThanOrEqualTo(heading.top));
        expect(back.left, lessThan(heading.center.dx));
        expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      });
    });

    testWidgets('the resend line sits above the Verify button', (tester) async {
      await withMustChangeLogin(tester, (verify) async {
        final resend = tester.getRect(find.text('Didn’t receive the email?'));
        final button = tester.getRect(find.byType(AuthBtn));
        final boxes = tester.getRect(find.byType(Pinput));
        expect(resend.top, greaterThan(boxes.bottom));
        expect(resend.bottom, lessThan(button.top));
      });
    });

    testWidgets('the code boxes fill the width like the button', (
      tester,
    ) async {
      await withMustChangeLogin(tester, (verify) async {
        final boxes = tester.getRect(find.byType(Pinput));
        final button = tester.getRect(find.byType(AuthBtn));
        expect(boxes.left, closeTo(button.left, 1));
        expect(boxes.right, closeTo(button.right, 1));
      });
    });
  });

  testWidgets('change-password screen: website labels, three icons and '
      'hint wording', (tester) async {
    await withMustChangeLogin(tester, (verify) async {
      verify('001234');
      await tester.pumpAndSettle();
      expect(find.byType(ChangePasswordCard), findsOneWidget);
      for (final label in [
        'Current password',
        'New password',
        'Confirm new password',
      ]) {
        expectWebsiteLabel(tester, label);
      }
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.key_outlined), findsOneWidget);
      expect(find.byIcon(Icons.verified_user_outlined), findsOneWidget);
      for (final icon in solidBoxIcons) {
        expect(find.byIcon(icon), findsNothing);
      }
      expect(find.text('Enter current password'), findsOneWidget);
      expect(find.text('Enter new password'), findsOneWidget);
      expect(find.text('Re-enter new password'), findsOneWidget);
    });
  });

  group('forgot-password screens', () {
    setUp(() {
      // The recovery screens get their own bloc from the service locator.
      final client = contractClient(
        (options) async => throw StateError('Unexpected ${options.path}'),
      );
      addTearDown(client.dio.close);
      final repository = PasswordRecoveryRepositoryImpl(
        PasswordRecoveryRemoteDataSourceImpl(client),
      );
      sl.registerFactory<PasswordRecoveryBloc>(
        () => PasswordRecoveryBloc(
          findAccountUseCase: FindAccountUseCase(repository),
          sendOtpUseCase: SendOtpUseCase(repository),
          verifyOtpUseCase: VerifyCodeUseCase(repository),
          resetPasswordUseCase: ResetPasswordUseCase(repository),
        ),
      );
      addTearDown(() => sl.unregister<PasswordRecoveryBloc>());
    });

    testWidgets('find account: website label and outline icon', (tester) async {
      await withLogin(tester, (router, bloc) async {
        router.push(Routes.findAccount);
        await tester.pumpAndSettle();
        expect(find.text('USERNAME'), findsNothing);
        expectWebsiteLabel(tester, 'Username');
        expect(find.byIcon(Icons.person_rounded), findsNothing);
        expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
      });
    });
  });

  testWidgets('reset password boxes: website labels and outline icons', (
    tester,
  ) async {
    final newPassword = TextEditingController();
    final confirm = TextEditingController();
    addTearDown(newPassword.dispose);
    addTearDown(confirm.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ResetPasswordFields(
              newPasswordController: newPassword,
              confirmNewPasswordController: confirm,
            ),
          ),
        ),
      ),
    );
    expectWebsiteLabel(tester, 'New password');
    expectWebsiteLabel(tester, 'Confirm new password');
    for (final icon in solidBoxIcons) {
      expect(find.byIcon(icon), findsNothing);
    }
    expect(find.byIcon(Icons.lock_outline_rounded), findsNWidgets(2));
  });
}
