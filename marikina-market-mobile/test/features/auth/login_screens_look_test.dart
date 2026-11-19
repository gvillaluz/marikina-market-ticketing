import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:marikina_market_mobile/features/auth/presentation/widgets/change_password_card.dart';
import 'package:marikina_market_mobile/features/auth/presentation/widgets/login_card.dart';
import 'package:marikina_market_mobile/features/auth/presentation/widgets/login_otp_card.dart';
import 'package:marikina_market_mobile/features/password_recovery/data/data_sources/password_recovery_remote_data_source.dart';
import 'package:marikina_market_mobile/features/password_recovery/data/repositories/password_recovery_repository_impl.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/use_cases/find_account_use_case.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/use_cases/reset_password_use_case.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/use_cases/send_otp_use_case.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/use_cases/verify_code_use_case.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/bloc/password_recovery_bloc.dart';
import 'package:marikina_market_mobile/core/di/dependency_injection.dart';

import '../../core/login_frame_test.dart' show bandHeadline, withLogin;
import 'data/login_mobile_contract_test.dart'
    show contractClient, otpResponse, profileResponse, reply, tokenResponse;

const subtitle = 'Use your staff username and password.';
const codeNote = 'Next, we email you a 6-digit code to finish logging in.';

/// Logs in with a temporary password, so the code screen and then the
/// change-password screen open inside the real login frame.
Future<void> withMustChangeLogin(
  WidgetTester tester,
  Future<void> Function(void Function(String code) verify) body,
) => withLogin(
  tester,
  respond: (options) async => switch (options.path) {
    '/auth/verify-login-mobile' => reply(options, tokenResponse),
    '/user/me' => reply(options, {
      ...profileResponse,
      'mustChangedPassword': true,
    }),
    _ => reply(options, otpResponse),
  },
  (router, bloc) async {
    bloc.add(
      LoginSubmitted(username: 'enforcer01', password: 'ExamplePass123'),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LoginOtpCard), findsOneWidget);
    await body((code) => bloc.add(VerifyLoginSubmitted(code)));
  },
);

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('log in screen', () {
    testWidgets('has a "Log in" heading and the subtitle above the fields', (
      tester,
    ) async {
      await withLogin(tester, (router, bloc) async {
        expect(find.byType(LoginCard), findsOneWidget);
        final username = tester.getRect(find.byType(TextField).first);
        final heading = find.text('Log in').first;
        expect(tester.getRect(heading).bottom, lessThan(username.top));
        expect(find.text(subtitle), findsOneWidget);
        expect(
          tester.getRect(find.text(subtitle)).top,
          greaterThan(tester.getRect(heading).bottom),
        );
        expect(
          tester.getRect(find.text(subtitle)).bottom,
          lessThan(username.top),
        );
      });
    });

    testWidgets('"Forgot password?" is on the PASSWORD label line, on the '
        'right, with a full-size tap area', (tester) async {
      await withLogin(tester, (router, bloc) async {
        final label = tester.getRect(find.text('PASSWORD'));
        final password = tester.getRect(find.byType(TextField).last);
        final forgot = tester.getRect(
          find.widgetWithText(TextButton, 'Forgot password?'),
        );
        expect(forgot.top, lessThanOrEqualTo(label.center.dy));
        expect(forgot.bottom, greaterThanOrEqualTo(label.center.dy));
        expect(forgot.bottom, lessThanOrEqualTo(password.top));
        expect(forgot.right, closeTo(password.right, 1));
        expect(forgot.height, greaterThanOrEqualTo(48));
      });
    });

    testWidgets('there is no code note under the Log in button', (
      tester,
    ) async {
      await withLogin(tester, (router, bloc) async {
        expect(find.text(codeNote), findsNothing);
      });
    });

    testWidgets('the fields line up with the band text', (tester) async {
      await withLogin(tester, (router, bloc) async {
        expect(
          tester.getRect(find.byType(TextField).first).left,
          tester.getRect(find.text(bandHeadline)).left,
        );
      });
    });
  });

  group('going back to the log in screen', () {
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

    // No overflow while the screens change, and once settled the screen
    // area is as tall as the log in screen, so nothing of it is trimmed.
    void expectWholeLogInScreen(WidgetTester tester) {
      expect(tester.takeException(), isNull);
      final screen = find.byType(LoginCard);
      expect(screen, findsOneWidget);
      final area = find
          .ancestor(of: screen, matching: find.byType(ClipRect))
          .first;
      expect(
        tester.getRect(find.text('Log in').last).bottom,
        lessThanOrEqualTo(tester.getRect(area).bottom),
      );
      expect(tester.getRect(screen).height, tester.getRect(area).height);
    }

    testWidgets('from step 1 shows the whole screen', (tester) async {
      await withLogin(tester, (router, bloc) async {
        router.push(Routes.findAccount);
        await tester.pumpAndSettle();
        expect(find.text('Step 1 of 4'), findsOneWidget);
        expect(tester.takeException(), isNull);
        router.pop();
        await tester.pumpAndSettle();
        expectWholeLogInScreen(tester);
      });
    });
  });

  testWidgets('the code screen heading is "Sign-in verification" without the '
      'shield icon', (tester) async {
    await withMustChangeLogin(tester, (verify) async {
      expect(find.text('Sign-in verification'), findsOneWidget);
      expect(find.text('SIGN-IN VERIFICATION'), findsNothing);
      expect(find.byIcon(Icons.verified_user_outlined), findsNothing);
      expect(
        tester.getRect(find.text('Sign-in verification')).left,
        tester.getRect(find.text(bandHeadline)).left,
      );
    });
  });

  testWidgets('the change-password heading is "Change password", lined up '
      'on the left with its text and fields', (tester) async {
    await withMustChangeLogin(tester, (verify) async {
      verify('001234');
      await tester.pumpAndSettle();
      expect(find.byType(ChangePasswordCard), findsOneWidget);
      expect(find.text('CHANGE PASSWORD'), findsNothing);
      final heading = tester.getRect(find.text('Change password'));
      final body = tester.getRect(find.textContaining('For your security'));
      final field = tester.getRect(find.byType(TextField).first);
      final band = tester.getRect(find.text(bandHeadline));
      expect(heading.left, band.left);
      expect(body.left, band.left);
      expect(field.left, band.left);
    });
  });

  testWidgets('nothing is cut off on a 320 px phone with text at 1.3x', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await withMustChangeLogin(tester, (verify) async {
      expect(find.text('Sign-in verification'), findsOneWidget);
      expect(tester.takeException(), isNull);
      verify('001234');
      await tester.pumpAndSettle();
      expect(find.text('Change password'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('the log in screen fits a 320 px phone with text at 1.3x', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await withLogin(tester, (router, bloc) async {
      expect(find.text(subtitle), findsOneWidget);
      expect(find.text('Log in'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  });
}
