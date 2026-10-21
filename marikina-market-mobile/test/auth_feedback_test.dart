import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/connectivity/cubit/connectivity_cubit.dart';
import 'package:marikina_market_mobile/core/router/mobile_route_access.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:marikina_market_mobile/features/auth/presentation/widgets/logout_progress_overlay.dart';
import 'features/auth/login_mobile_flow_test.dart' show loginBloc, startLogin;
import 'features/auth/login_test_network_info.dart';
import 'features/auth/data/login_mobile_contract_test.dart'
    show reply, otpResponse;
import 'mobile_role_navigation_test.dart' show authenticate;
import 'profile_preview_capture.dart';
import 'package:marikina_market_mobile/features/auth/presentation/pages/login_otp_page.dart';
import 'package:marikina_market_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:marikina_market_mobile/features/auth/presentation/pages/mandatory_change_password_page.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/pages/find_account_page.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/pages/reset_password_page.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/bloc/password_recovery_bloc.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/bloc/password_recovery_state.dart';
import 'package:marikina_market_mobile/features/password_recovery/data/repositories/password_recovery_repository_impl.dart';
import 'package:marikina_market_mobile/features/password_recovery/data/data_sources/password_recovery_remote_data_source.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/use_cases/find_account_use_case.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/use_cases/send_otp_use_case.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/use_cases/verify_code_use_case.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/use_cases/reset_password_use_case.dart';
import 'package:marikina_market_mobile/core/router/route_args.dart';
import 'features/auth/data/login_mobile_contract_test.dart' show contractClient;

void main() {
  setUpAll(loadProfilePreviewFonts);
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  for (final rejected in [false, true]) {
    testWidgets(
      'logout shows progress, blocks taps, preserves the route and completes once (${rejected ? 'rejected' : 'success'})',
      (tester) async {
        late AuthBloc auth;
        late Completer<void> gate;
        late Completer<void> requested;
        var requests = 0;
        var logoutTaps = 0;
        await tester.runAsync(() async {
          gate = Completer<void>();
          requested = Completer<void>();
          final connectivity = ConnectivityCubit(LoginTestNetworkInfo());
          addTearDown(connectivity.close);
          auth = loginBloc(connectivity, (options) async {
            expect(options.path.toLowerCase(), '/auth/logout');
            requests++;
            if (!requested.isCompleted) requested.complete();
            await gate.future;
            if (rejected) {
              throw DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response<Object?>(
                  requestOptions: options,
                  statusCode: 400,
                  data: {'message': 'Logout rejected.'},
                ),
              );
            }
            return reply(options, {'message': 'Logged out.'});
          });
          await auth.stream.firstWhere((state) => state is Unauthenticated);
          await authenticate(auth, 'MarketVendor');
          const storage = FlutterSecureStorage();
          await storage.write(key: 'device_token', value: 'synthetic-device');
          await storage.write(key: 'refresh_token', value: 'synthetic-refresh');
        });
        addTearDown(() {
          if (!gate.isCompleted) gate.complete();
          unawaited(auth.close());
        });
        final key = GlobalKey();
        await tester.pumpWidget(
          BlocProvider.value(
            value: auth,
            child: RepaintBoundary(
              key: key,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: profilePreviewTheme,
                builder: (_, child) => LogoutProgressOverlay(child: child!),
                home: Scaffold(
                  body: TextButton(
                    onPressed: () {
                      logoutTaps++;
                      auth.add(LogoutUser(false));
                    },
                    child: const Text('Log Out'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.runAsync(() async {
          await tester.tap(find.text('Log Out'));
          await requested.future;
        });
        await tester.pump();
        expect(auth.state, isA<Authenticated>());
        expect(
          MobileRouteAccess.redirect(auth.state, Routes.vendorDashboard),
          isNull,
        );
        expect(find.text('Signing out…'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is ModalBarrier &&
                widget.color == AppTheme.authLogoutBarrierColor &&
                !widget.dismissible,
          ),
          findsOneWidget,
        );
        await tester.tapAt(tester.getCenter(find.text('Log Out')));
        expect(logoutTaps, 1);
        await tester.pump(const Duration(milliseconds: 300));
        await captureProfilePreview(tester, key, 'logout-progress');
        await tester.runAsync(() async {
          auth.add(UserUpdated((auth.state as Authenticated).user));
          await Future<void>.delayed(Duration.zero);
        });
        await tester.pump();
        expect(find.text('Signing out…'), findsOneWidget);
        await tester.runAsync(() async {
          auth.add(LogoutUser(false));
          await Future<void>.delayed(Duration.zero);
          expect(requests, 1);
          final finished = auth.stream.firstWhere(
            (state) => rejected
                ? state is AuthConnectionError
                : state is Unauthenticated,
          );
          gate.complete();
          await finished;
        });
        await tester.pumpAndSettle();
        expect(find.text('Signing out…'), findsNothing);
        expect(requests, 1);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  for (final mandatory in [false, true]) {
    testWidgets(
      '${mandatory ? 'mandatory password' : 'login'} error card retains entered values',
      (tester) async {
        tester.view.physicalSize = const Size(390, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        late AuthBloc auth;
        await tester.runAsync(() async {
          final connectivity = ConnectivityCubit(LoginTestNetworkInfo());
          addTearDown(connectivity.close);
          auth = loginBloc(connectivity, (options) async {
            throw DioException(
              requestOptions: options,
              type: mandatory
                  ? DioExceptionType.connectionError
                  : DioExceptionType.badResponse,
              response: mandatory
                  ? null
                  : Response<Object?>(
                      requestOptions: options,
                      statusCode: 400,
                      data: {'message': 'Incorrect username or password.'},
                    ),
            );
          });
          await auth.stream.firstWhere((state) => state is Unauthenticated);
          if (mandatory) {
            await authenticate(auth, 'MarketVendor', mustChangePassword: true);
          }
        });
        addTearDown(() {
          unawaited(auth.close());
        });
        final key = GlobalKey();
        await tester.pumpWidget(
          BlocProvider.value(
            value: auth,
            child: RepaintBoundary(
              key: key,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: profilePreviewTheme,
                home: mandatory
                    ? const MandatoryChangePasswordPage()
                    : const LoginPage(),
              ),
            ),
          ),
        );
        final values = mandatory
            ? ['OldPass123', 'NewPass123', 'NewPass123']
            : ['vendor01', 'ExamplePass123'];
        for (var i = 0; i < values.length; i++) {
          await tester.enterText(find.byType(TextField).at(i), values[i]);
        }
        final submit = find.text(mandatory ? 'UPDATE PASSWORD' : 'LOGIN');
        await tester.ensureVisible(submit);
        await tester.runAsync(() async {
          final failed = auth.stream.firstWhere(
            (state) => mandatory
                ? state is AuthChangePasswordNetworkError
                : state is AuthInvalidCredentials,
          );
          await tester.tap(submit);
          await failed;
        });
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(
          find.text(
            mandatory
                ? 'No internet connection. Please try again.'
                : 'Incorrect username or password.',
          ),
          findsOneWidget,
        );
        expect(find.byType(SnackBar), findsNothing);
        for (var i = 0; i < values.length; i++) {
          expect(
            tester
                .widget<TextField>(find.byType(TextField).at(i))
                .controller!
                .text,
            values[i],
          );
        }
        await captureProfilePreview(
          tester,
          key,
          mandatory ? 'mandatory-password-error' : 'login-error',
        );
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  for (final reset in [false, true]) {
    testWidgets(
      '${reset ? 'reset password' : 'find account'} error is inline and preserves inputs',
      (tester) async {
        tester.view.physicalSize = const Size(390, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final client = contractClient(
          (options) async => throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          ),
        );
        addTearDown(client.dio.close);
        late PasswordRecoveryBloc recovery;
        await tester.runAsync(() async {
          final repository = PasswordRecoveryRepositoryImpl(
            PasswordRecoveryRemoteDataSourceImpl(client),
          );
          recovery = PasswordRecoveryBloc(
            findAccountUseCase: FindAccountUseCase(repository),
            sendOtpUseCase: SendOtpUseCase(repository),
            verifyOtpUseCase: VerifyCodeUseCase(repository),
            resetPasswordUseCase: ResetPasswordUseCase(repository),
          );
        });
        addTearDown(() {
          unawaited(recovery.close());
        });
        final key = GlobalKey();
        await tester.pumpWidget(
          BlocProvider.value(
            value: recovery,
            child: RepaintBoundary(
              key: key,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: profilePreviewTheme,
                home: reset
                    ? ResetPasswordPage(
                        args: ResetPasswordArgs(
                          username: 'vendor01',
                          resetToken: 'synthetic-reset',
                        ),
                      )
                    : const FindAccountPage(),
              ),
            ),
          ),
        );
        final values = reset ? ['NewPass123', 'NewPass123'] : ['vendor01'];
        for (var i = 0; i < values.length; i++) {
          await tester.enterText(find.byType(TextField).at(i), values[i]);
        }
        final submit = find.text(reset ? 'Change Password' : 'Continue');
        await tester.ensureVisible(submit);
        await tester.runAsync(() async {
          final failed = recovery.stream.firstWhere(
            (state) => reset
                ? state is ResetPasswordFailed
                : state is SearchAccountFailed,
          );
          await tester.tap(submit);
          await failed;
        });
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(
          find.text('No internet connection. Please try again.'),
          findsOneWidget,
        );
        expect(find.byType(SnackBar), findsNothing);
        for (var i = 0; i < values.length; i++) {
          expect(
            tester
                .widget<TextField>(find.byType(TextField).at(i))
                .controller!
                .text,
            values[i],
          );
        }
        await captureProfilePreview(
          tester,
          key,
          reset ? 'reset-password-error' : 'find-account-error',
        );
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'verification error fits with keyboard and preserves the entered code',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 220);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      late AuthBloc auth;
      String? submitted;
      await tester.runAsync(() async {
        final connectivity = ConnectivityCubit(LoginTestNetworkInfo());
        addTearDown(connectivity.close);
        auth = loginBloc(connectivity, (options) async {
          if (options.path == '/auth/login-mobile') {
            return reply(options, otpResponse);
          }
          submitted = (options.data as Map<String, Object?>)['code'] as String;
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response<Object?>(
              requestOptions: options,
              statusCode: 400,
              data: {'message': 'Incorrect code. Try again.'},
            ),
          );
        });
        await startLogin(auth);
      });
      addTearDown(() {
        unawaited(auth.close());
      });
      final key = GlobalKey();
      await tester.pumpWidget(
        BlocProvider.value(
          value: auth,
          child: RepaintBoundary(
            key: key,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: profilePreviewTheme,
              home: const LoginOtpPage(),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), '001234');
      await tester.ensureVisible(find.text('Verify & sign in'));
      await tester.runAsync(() async {
        final failed = auth.stream.firstWhere(
          (state) =>
              state is LoginOtpPending &&
              state.message == 'Incorrect code. Try again.',
        );
        await tester.tap(find.text('Verify & sign in'));
        await failed;
      });
      await tester.pumpAndSettle();
      expect(submitted, '001234');
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        '001234',
      );
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Incorrect code. Try again.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await captureProfilePreview(tester, key, 'verification-error-keyboard');
      await tester.pumpWidget(const SizedBox());
    },
  );
}
