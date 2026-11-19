import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/connectivity/cubit/connectivity_cubit.dart';
import 'package:marikina_market_mobile/core/di/dependency_injection.dart';
import 'package:marikina_market_mobile/core/router/app_router.dart';
import 'package:marikina_market_mobile/core/router/route_args.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/login_band.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/login_frame.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:marikina_market_mobile/features/auth/presentation/widgets/change_password_card.dart';
import 'package:marikina_market_mobile/features/auth/presentation/widgets/login_card.dart';
import 'package:marikina_market_mobile/features/auth/presentation/widgets/login_otp_card.dart';
import 'package:marikina_market_mobile/features/password_recovery/data/data_sources/password_recovery_remote_data_source.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/entities/account_lookup.dart';
import 'package:marikina_market_mobile/features/password_recovery/data/repositories/password_recovery_repository_impl.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/use_cases/find_account_use_case.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/use_cases/reset_password_use_case.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/use_cases/send_otp_use_case.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/use_cases/verify_code_use_case.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/bloc/password_recovery_bloc.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/pages/find_account_page.dart';

import '../features/auth/data/login_mobile_contract_test.dart'
    show contractClient, otpResponse, profileResponse, reply, tokenResponse;
import '../features/auth/login_mobile_flow_test.dart' show loginBloc;
import '../features/auth/login_test_network_info.dart';

/// Shows the real login routes, runs [body], then tears everything down.
Future<void> withLogin(
  WidgetTester tester,
  Future<void> Function(GoRouter router, AuthBloc bloc) body, {
  bool reduceMotion = false,
  bool settle = true,
  Future<Response<Object?>> Function(RequestOptions)? respond,
}) async {
  final connectivity = ConnectivityCubit(LoginTestNetworkInfo());
  addTearDown(connectivity.close);
  final bloc = loginBloc(
    connectivity,
    respond ?? (options) async => reply(options, otpResponse),
  );
  final appRouter = AppRouter(authBloc: bloc);
  // The device's "remove animations" setting, as the framework itself sees it.
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: reduceMotion);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  try {
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: appRouter.router,
        ),
      ),
    );
    if (settle) await tester.pumpAndSettle();
    await body(appRouter.router, bloc);
  } finally {
    await tester.pumpWidget(const SizedBox.shrink());
    unawaited(bloc.close());
  }
}

/// Left edge of [screen] a moment after it appears, and once it has settled.
/// A move that waits for the server is given a few frames to show the screen.
Future<(double, double)> slideOf(
  WidgetTester tester,
  Finder screen,
  void Function() move,
) async {
  move();
  await tester.pump();
  for (var frames = 0; frames < 100 && screen.evaluate().isEmpty; frames++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
  await tester.pump(const Duration(milliseconds: 80));
  final during = tester.getTopLeft(screen).dx;
  await tester.pumpAndSettle();
  return (during, tester.getTopLeft(screen).dx);
}

/// Sends Android's predictive-back messages to the framework.
Future<void> sendBackGesture(WidgetTester tester, String method) async {
  const codec = StandardMethodCodec();
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/backgesture',
    codec.encodeMethodCall(
      MethodCall(method, <String, Object?>{
        'touchOffset': <double>[10, 600],
        'progress': 0.0,
        'swipeEdge': 0,
      }),
    ),
    (_) {},
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
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

  testWidgets(
    'the frame and its header are not rebuilt between login screens',
    (tester) async {
      await withLogin(tester, (router, bloc) async {
        expect(find.byType(LoginCard), findsOneWidget);
        final frame = tester.element(find.byType(LoginFrame));
        final header = tester.element(find.byType(LoginBand));

        bloc.add(
          LoginSubmitted(username: 'enforcer01', password: 'ExamplePass123'),
        );
        await tester.pumpAndSettle();
        expect(find.byType(LoginOtpCard), findsOneWidget);
        expect(find.byType(LoginBand), findsOneWidget);
        expect(tester.element(find.byType(LoginFrame)), same(frame));
        expect(tester.element(find.byType(LoginBand)), same(header));

        bloc.add(CancelLogin());
        await tester.pumpAndSettle();
        expect(find.byType(LoginCard), findsOneWidget);
        expect(tester.element(find.byType(LoginFrame)), same(frame));

        router.push(Routes.findAccount);
        await tester.pumpAndSettle();
        expect(find.byType(FindAccountPage), findsOneWidget);
        expect(find.byType(LoginBand), findsOneWidget);
        expect(tester.element(find.byType(LoginFrame)), same(frame));
      });
    },
  );

  testWidgets('each login address opens its own screen inside one frame', (
    tester,
  ) async {
    await withLogin(tester, (router, bloc) async {
      router.go(Routes.findAccount);
      await tester.pumpAndSettle();
      expect(find.byType(FindAccountPage), findsOneWidget);
      expect(find.text('Step 1 of 4'), findsOneWidget);
      expect(find.byType(LoginFrame), findsOneWidget);
      router.go(Routes.login);
      await tester.pumpAndSettle();
      expect(find.byType(LoginCard), findsOneWidget);
      expect(find.byType(LoginFrame), findsOneWidget);
    });
  });

  group('slide between login screens', () {
    testWidgets('moving forward slides the new screen in from the right', (
      tester,
    ) async {
      await withLogin(tester, (router, bloc) async {
        final (during, settled) = await slideOf(
          tester,
          find.byType(FindAccountPage),
          () => router.push(Routes.findAccount),
        );
        expect(during, greaterThan(settled));
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('the login code screen also slides in from the right', (
      tester,
    ) async {
      await withLogin(tester, (router, bloc) async {
        final (during, settled) = await slideOf(
          tester,
          find.byType(LoginOtpCard),
          () => bloc.add(
            LoginSubmitted(username: 'enforcer01', password: 'ExamplePass123'),
          ),
        );
        expect(during, greaterThan(settled));
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('going back slides the earlier screen in from the left', (
      tester,
    ) async {
      await withLogin(tester, (router, bloc) async {
        router.push(Routes.findAccount);
        await tester.pumpAndSettle();
        final (during, settled) = await slideOf(
          tester,
          find.byType(LoginCard),
          router.pop,
        );
        expect(during, lessThan(settled));
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('"Back to log in" slides the login screen in from the left', (
      tester,
    ) async {
      await withLogin(tester, (router, bloc) async {
        router.push(Routes.findAccount);
        await tester.pumpAndSettle();
        final (during, settled) = await slideOf(
          tester,
          find.byType(LoginCard),
          () => router.go(Routes.login),
        );
        expect(during, lessThan(settled));
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('with animations removed a screen is in place at once', (
      tester,
    ) async {
      await withLogin(tester, reduceMotion: true, (router, bloc) async {
        final (during, settled) = await slideOf(
          tester,
          find.byType(FindAccountPage),
          () => router.push(Routes.findAccount),
        );
        expect(during, settled);
        expect(tester.takeException(), isNull);
      });
    });
    testWidgets('with animations removed going back shows the earlier screen', (
      tester,
    ) async {
      await withLogin(tester, reduceMotion: true, (router, bloc) async {
        router.push(Routes.findAccount);
        await tester.pumpAndSettle();
        expect(find.byType(FindAccountPage), findsOneWidget);
        router.pop();
        await tester.pump();
        expect(find.byType(LoginCard), findsOneWidget);
        // The heading and the button.
        expect(find.text('Log in'), findsNWidgets(2));
        await tester.pumpAndSettle();
        expect(find.byType(LoginCard), findsOneWidget);
        // The heading and the button.
        expect(find.text('Log in'), findsNWidgets(2));
        expect(find.byType(FindAccountPage), findsNothing);
        expect(tester.takeException(), isNull);
      });
    });
    testWidgets('with animations removed back from step 2 shows step 1', (
      tester,
    ) async {
      await withLogin(tester, reduceMotion: true, (router, bloc) async {
        router.push(Routes.findAccount);
        await tester.pumpAndSettle();
        router.pushNamed(
          Routes.forgotPasswordOptionName,
          extra: ForgotPasswordOptionArgs(
            username: 'enforcer01',
            account: AccountLookup(
              found: true,
              maskedEmail: 'e***@example.com',
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Step 2 of 4'), findsOneWidget);
        // Android 16 delivers Back as a predictive-back gesture: start, then
        // commit.
        await sendBackGesture(tester, 'startBackGesture');
        await sendBackGesture(tester, 'commitBackGesture');
        await tester.pump();
        expect(find.text('Step 1 of 4'), findsOneWidget);
        await tester.pumpAndSettle();
        expect(find.text('Step 1 of 4'), findsOneWidget);
        expect(find.text('Step 2 of 4'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    });
  });

  testWidgets('the header title stays readable to screen readers', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await withLogin(tester, (router, bloc) async {
      const title = 'Marikina Public Market Inspection System';
      expect(find.bySemanticsLabel(title), findsOneWidget);
      router.push(Routes.findAccount);
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(title), findsOneWidget);
      bloc.add(CancelLogin());
    });
    semantics.dispose();
  });

  group('opening sequence', () {
    double shown(WidgetTester tester, Finder inside) => tester
        .widget<FadeTransition>(
          find
              .ancestor(of: inside, matching: find.byType(FadeTransition))
              .first,
        )
        .opacity
        .value;

    // The band's last picture is the seal beside the name; the first is the
    // faint seal in the corner.
    double sealShown(WidgetTester tester) =>
        shown(tester, find.byType(Image).last);
    double nameShown(WidgetTester tester) => shown(tester, find.text(bandName));
    double headlineShown(WidgetTester tester) =>
        shown(tester, find.text(bandHeadline));

    testWidgets('the seal, name and headline appear in turn, then the form', (
      tester,
    ) async {
      await withLogin(settle: false, tester, (router, bloc) async {
        // The app first shows its start-up screen; wait for the login frame.
        for (
          var i = 0;
          i < 100 && find.byType(LoginCard).evaluate().isEmpty;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 10));
        }
        await tester.pump(const Duration(milliseconds: 120));
        final card = find.byType(LoginCard);
        expect(sealShown(tester), greaterThan(0));
        expect(nameShown(tester), lessThan(sealShown(tester)));
        expect(headlineShown(tester), lessThan(nameShown(tester)));
        expect(shown(tester, card), 0);
        final rising = tester.getTopLeft(card).dy;
        await tester.pumpAndSettle();
        expect(sealShown(tester), 1);
        expect(nameShown(tester), 1);
        expect(headlineShown(tester), 1);
        expect(shown(tester, card), 1);
        expect(rising, greaterThan(tester.getTopLeft(card).dy));
      });
    });

    testWidgets('it plays once, not again on every screen change', (
      tester,
    ) async {
      await withLogin(tester, (router, bloc) async {
        router.push(Routes.findAccount);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 10));
        expect(headlineShown(tester), 1);
        expect(shown(tester, find.byType(FindAccountPage)), greaterThan(0));
        await tester.pumpAndSettle();
        router.pop();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 10));
        expect(headlineShown(tester), 1);
      });
    });

    testWidgets('with animations removed everything is there at once', (
      tester,
    ) async {
      await withLogin(settle: false, reduceMotion: true, tester, (
        router,
        bloc,
      ) async {
        for (
          var i = 0;
          i < 100 && find.byType(LoginCard).evaluate().isEmpty;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 10));
        }
        expect(sealShown(tester), 1);
        expect(nameShown(tester), 1);
        expect(headlineShown(tester), 1);
        expect(shown(tester, find.byType(LoginCard)), 1);
      });
    });
  });

  group('navy band', () {
    testWidgets('the band and the note show on every login screen', (
      tester,
    ) async {
      final account = AccountLookup(
        found: true,
        maskedEmail: 'e***@example.com',
      );
      await withLogin(
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
          Future<void> expectBandOn(Finder screen) async {
            await tester.pumpAndSettle();
            expect(screen, findsOneWidget);
            expect(find.text(bandName), findsOneWidget);
            expect(find.text(bandSystem), findsOneWidget);
            expect(find.text(bandHeadline), findsOneWidget);
            expect(find.text(bandNote), findsOneWidget);
          }

          await expectBandOn(find.byType(LoginCard));
          router.push(Routes.findAccount);
          await expectBandOn(find.text('Step 1 of 4'));
          router.goNamed(
            Routes.forgotPasswordOptionName,
            extra: ForgotPasswordOptionArgs(
              username: 'enforcer01',
              account: account,
            ),
          );
          await expectBandOn(find.text('Step 2 of 4'));
          router.goNamed(
            Routes.codeVerificationName,
            extra: CodeValidationArgs(
              username: 'enforcer01',
              channel: 'email',
              account: account,
            ),
          );
          await expectBandOn(find.text('Step 3 of 4'));
          router.goNamed(
            Routes.resetPasswordName,
            extra: ResetPasswordArgs(
              username: 'enforcer01',
              resetToken: 'test-reset-token',
            ),
          );
          await expectBandOn(find.text('Step 4 of 4'));
          router.go(Routes.login);
          await expectBandOn(find.byType(LoginCard));
          bloc.add(
            LoginSubmitted(username: 'enforcer01', password: 'ExamplePass123'),
          );
          await expectBandOn(find.byType(LoginOtpCard));
          bloc.add(VerifyLoginSubmitted('001234'));
          await expectBandOn(find.byType(ChangePasswordCard));
        },
      );
    });

    testWidgets('the form sits on the page, not inside a raised card', (
      tester,
    ) async {
      await withLogin(tester, (router, bloc) async {
        final raised = find.ancestor(
          of: find.byType(LoginCard),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.decoration is BoxDecoration &&
                (widget.decoration! as BoxDecoration).boxShadow != null,
          ),
        );
        expect(find.byType(LoginCard), findsOneWidget);
        expect(raised, findsNothing);
      });
    });

    testWidgets('screen readers hear the name, the headline and the note, '
        'and skip the seal pictures', (tester) async {
      final semantics = tester.ensureSemantics();
      await withLogin(tester, (router, bloc) async {
        final name = find.bySemanticsLabel(
          'Marikina Public Market Inspection System',
        );
        final headline = find.bySemanticsLabel(bandHeadline);
        expect(name, findsOneWidget);
        expect(headline, findsOneWidget);
        expect(find.bySemanticsLabel(bandNote), findsOneWidget);
        expect(
          tester.getRect(name).top,
          lessThan(tester.getRect(headline).top),
        );
        final pictures = tester.widgetList<Image>(find.byType(Image));
        expect(pictures, hasLength(2));
        for (final picture in pictures) {
          expect(picture.excludeFromSemantics, isTrue);
        }
      });
      semantics.dispose();
    });

    testWidgets('band text and the note keep a 4.5 to 1 contrast', (
      tester,
    ) async {
      await withLogin(tester, (router, bloc) async {
        for (final text in [bandName, bandSystem, bandHeadline]) {
          final band = tester
              .widget<ColoredBox>(
                find
                    .ancestor(
                      of: find.text(text),
                      matching: find.byType(ColoredBox),
                    )
                    .first,
              )
              .color;
          final color = tester.widget<Text>(find.text(text)).style!.color!;
          expect(contrastOf(color, band), greaterThanOrEqualTo(4.5));
        }
        final page = Theme.of(
          tester.element(find.text(bandNote)),
        ).scaffoldBackgroundColor;
        final note = tester.widget<Text>(find.text(bandNote)).style!.color!;
        expect(contrastOf(note, page), greaterThanOrEqualTo(4.5));
      });
    });

    testWidgets('status bar icons are light on the band and dark on the page', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await withLogin(tester, (router, bloc) async {
        expect(
          SystemChrome.latestStyle?.statusBarIconBrightness,
          Brightness.light,
        );
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
        await tester.pumpAndSettle();
        expect(find.text(bandHeadline).hitTestable(), findsNothing);
        expect(
          SystemChrome.latestStyle?.statusBarIconBrightness,
          Brightness.dark,
        );
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
      await withLogin(tester, (router, bloc) async {
        expect(tester.getRect(find.text(bandHeadline)).right, lessThan(320));
        expect(tester.takeException(), isNull);
        router.push(Routes.findAccount);
        await tester.pumpAndSettle();
        expect(find.text('Step 1 of 4'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  });
}

const bandName = 'Marikina Public Market';
const bandSystem = 'Inspection System';
const bandHeadline = 'For recording market inspections and tickets.';
const bandNote = 'Need an account? Ask your Head Admin to create one for you.';

/// Contrast between [text] (blended over [background]) and [background], as
/// the accessibility guidelines measure it.
double contrastOf(Color text, Color background) {
  final front = Color.alphaBlend(text, background).computeLuminance();
  final back = background.computeLuminance();
  return (max(front, back) + 0.05) / (min(front, back) + 0.05);
}
