import 'dart:async';

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
import 'package:marikina_market_mobile/core/shared/presentation/widgets/login_card_header.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/login_frame.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_event.dart';
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
    show contractClient, otpResponse, reply;
import '../features/auth/login_mobile_flow_test.dart' show loginBloc;
import '../features/auth/login_test_network_info.dart';

/// Shows the real login routes, runs [body], then tears everything down.
Future<void> withLogin(
  WidgetTester tester,
  Future<void> Function(GoRouter router, AuthBloc bloc) body, {
  bool reduceMotion = false,
  bool settle = true,
}) async {
  final connectivity = ConnectivityCubit(LoginTestNetworkInfo());
  addTearDown(connectivity.close);
  final bloc = loginBloc(
    connectivity,
    (options) async => reply(options, otpResponse),
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
        final header = tester.element(find.byType(LoginCardHeader));

        bloc.add(
          LoginSubmitted(username: 'enforcer01', password: 'ExamplePass123'),
        );
        await tester.pumpAndSettle();
        expect(find.byType(LoginOtpCard), findsOneWidget);
        expect(find.byType(LoginCardHeader), findsOneWidget);
        expect(tester.element(find.byType(LoginFrame)), same(frame));
        expect(tester.element(find.byType(LoginCardHeader)), same(header));

        bloc.add(CancelLogin());
        await tester.pumpAndSettle();
        expect(find.byType(LoginCard), findsOneWidget);
        expect(tester.element(find.byType(LoginFrame)), same(frame));

        router.push(Routes.findAccount);
        await tester.pumpAndSettle();
        expect(find.byType(FindAccountPage), findsOneWidget);
        expect(find.byType(LoginCardHeader), findsOneWidget);
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
        expect(find.text('Log in'), findsOneWidget);
        await tester.pumpAndSettle();
        expect(find.byType(LoginCard), findsOneWidget);
        expect(find.text('Log in'), findsOneWidget);
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
    const title = 'Marikina Public Market Inspection System';

    double logoShown(WidgetTester tester) =>
        tester.widget<Image>(find.byType(Image)).opacity!.value;

    double titleShown(WidgetTester tester) =>
        tester.widget<Text>(find.text(title)).style!.color!.a;

    double shown(WidgetTester tester, Finder inside) => tester
        .widget<FadeTransition>(
          find
              .ancestor(of: inside, matching: find.byType(FadeTransition))
              .first,
        )
        .opacity
        .value;

    testWidgets('the logo and title appear first, then the card rises in', (
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
        expect(logoShown(tester), greaterThan(0));
        expect(titleShown(tester), lessThan(logoShown(tester)));
        expect(shown(tester, card), 0);
        final rising = tester.getTopLeft(card).dy;
        await tester.pumpAndSettle();
        expect(logoShown(tester), 1);
        expect(titleShown(tester), 1);
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
        expect(titleShown(tester), 1);
        expect(shown(tester, find.byType(FindAccountPage)), greaterThan(0));
        await tester.pumpAndSettle();
        router.pop();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 10));
        expect(titleShown(tester), 1);
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
        expect(logoShown(tester), 1);
        expect(titleShown(tester), 1);
        expect(shown(tester, find.byType(LoginCard)), 1);
      });
    });
  });
}
