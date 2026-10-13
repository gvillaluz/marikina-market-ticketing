import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/connectivity/cubit/connectivity_cubit.dart';
import 'package:marikina_market_mobile/core/router/app_router.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/check_auth_status_use_case.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/login_user_use_case.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/logout_user_use_case.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/sync_pending_logouts_use_case.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/mandatory_change_password_use_case.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/refresh_tokens_use_case.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/register_device_token_use_case.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/verify_login_use_case.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:marikina_market_mobile/features/auth/presentation/pages/login_otp_page.dart';
import 'package:marikina_market_mobile/features/auth/presentation/widgets/login_otp_card.dart';

import 'data/login_mobile_contract_test.dart'
    show contractClient, contractRepository, otpResponse, reply;
import 'login_test_network_info.dart';

AuthBloc loginBloc(
  ConnectivityCubit connectivity,
  Future<Response<Object?>> Function(RequestOptions) respond,
) {
  final client = contractClient(respond);
  addTearDown(client.dio.close);
  final repository = contractRepository(client);
  return AuthBloc(
    connectivityCubit: connectivity,
    checkAuthStatusUseCase: CheckAuthStatusUseCase(repository),
    loginUserUseCase: LoginUserUseCase(repository),
    verifyLoginUseCase: VerifyLoginUseCase(repository),
    logoutUserUseCase: LogoutUserUseCase(repository),
    syncPendingLogoutsUseCase: SyncPendingLogoutsUseCase(repository),
    mandatoryChangePasswordUseCase: MandatoryChangePasswordUseCase(repository),
    refreshTokensUseCase: RefreshTokensUseCase(repository),
    registerDeviceTokenUseCase: RegisterDeviceTokenUseCase(repository),
  );
}

Future<void> startLogin(AuthBloc bloc) async {
  final ready = bloc.stream.firstWhere((state) => state is Unauthenticated);
  await ready;
  final pending = bloc.stream.firstWhere((state) => state is LoginOtpPending);
  bloc.add(
    LoginSubmitted(username: 'enforcer01', password: ' ExamplePass123 '),
  );
  await pending;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'pending login blocks duplicate requests and verification after cancellation',
    () async {
      var sends = 0;
      var verifies = 0;
      final connectivity = ConnectivityCubit(LoginTestNetworkInfo());
      final bloc = loginBloc(connectivity, (options) async {
        if (options.path == '/auth/login-mobile') sends++;
        if (options.path == '/auth/verify-login-mobile') verifies++;
        return reply(options, otpResponse);
      });
      addTearDown(bloc.close);
      addTearDown(connectivity.close);
      await startLogin(bloc);
      expect(bloc.state, isA<LoginOtpPending>());
      bloc.add(LoginSubmitted(username: 'different', password: 'different'));
      bloc.add(ResendLoginOtp());
      await Future<void>.delayed(Duration.zero);
      expect(sends, 1);
      final cancelled = bloc.stream.firstWhere(
        (state) => state is Unauthenticated,
      );
      bloc.add(CancelLogin());
      await cancelled;
      bloc.add(VerifyLoginSubmitted('001234'));
      await Future<void>.delayed(Duration.zero);
      expect(verifies, 0);
      expect(await const FlutterSecureStorage().readAll(), isEmpty);
    },
  );

  test('attempt limit requires a resend using unchanged credentials', () async {
    var sends = 0;
    final connectivity = ConnectivityCubit(LoginTestNetworkInfo());
    final bloc = loginBloc(connectivity, (options) async {
      expect((options.data as Map)['password'], ' ExamplePass123 ');
      if (options.path == '/auth/login-mobile') {
        sends++;
        return reply(options, {
          ...otpResponse,
          'resend_cooldown_seconds': sends == 1 ? 0 : 30,
        });
      }
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response<Object?>(
          requestOptions: options,
          statusCode: 400,
          data: {'message': 'Too many attempts. Request a new code.'},
        ),
      );
    });
    addTearDown(bloc.close);
    addTearDown(connectivity.close);
    await startLogin(bloc);
    final failed = bloc.stream.firstWhere(
      (state) => state is LoginOtpPending && state.requiresNewCode,
    );
    bloc.add(VerifyLoginSubmitted('001234'));
    await failed;
    expect((bloc.state as LoginOtpPending).canVerify, isFalse);
    final resent = bloc.stream.firstWhere(
      (state) =>
          state is LoginOtpPending && !state.isBusy && !state.requiresNewCode,
    );
    bloc.add(ResendLoginOtp());
    await resent;
    expect(sends, 2);
    expect((bloc.state as LoginOtpPending).resendCooldownSeconds, 30);
    expect((bloc.state as LoginOtpPending).canVerify, isTrue);
  });

  test('late resend response cannot restore cancelled credentials', () async {
    var sends = 0;
    final response = Completer<Response<Object?>>();
    final connectivity = ConnectivityCubit(LoginTestNetworkInfo());
    final bloc = loginBloc(connectivity, (options) async {
      sends++;
      if (sends == 2) return response.future;
      return reply(options, {...otpResponse, 'resend_cooldown_seconds': 0});
    });
    addTearDown(bloc.close);
    addTearDown(connectivity.close);
    await startLogin(bloc);
    final sending = bloc.stream.firstWhere(
      (state) => state is LoginOtpPending && state.isResending,
    );
    bloc.add(ResendLoginOtp());
    await sending;
    final cancelled = bloc.stream.firstWhere(
      (state) => state is Unauthenticated,
    );
    bloc.add(CancelLogin());
    await cancelled;
    response.complete(
      Response<Object?>(
        requestOptions: RequestOptions(path: '/auth/login-mobile'),
        data: otpResponse,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state, isA<Unauthenticated>());
  });

  testWidgets(
    'OTP card fits a 320px screen with keyboard and preserves leading zeros',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 220);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final connectivity = ConnectivityCubit(LoginTestNetworkInfo());
      String? submittedCode;
      final bloc = loginBloc(connectivity, (options) async {
        if (options.path == '/auth/login-mobile') {
          return reply(options, otpResponse);
        }
        submittedCode = (options.data as Map)['code'] as String;
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
      addTearDown(bloc.close);
      addTearDown(connectivity.close);
      await tester.runAsync(() => startLogin(bloc));
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: MaterialApp(theme: AppTheme.light, home: const LoginOtpPage()),
        ),
      );
      expect(find.text('SIGN-IN VERIFICATION'), findsOneWidget);
      expect(find.textContaining('e***@example.com'), findsOneWidget);
      expect(
        find.text(
          'Enter the 6-digit code sent to e***@example.com to finish signing in.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Code expires in'), findsNothing);
      expect(find.text('Didn’t receive the email?'), findsOneWidget);
      expect(find.text('Resend in 00:30'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(EditableText), '001234');
      await tester.ensureVisible(find.text('Verify & sign in'));
      await tester.tap(find.text('Verify & sign in'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(submittedCode, '001234');
      expect(find.text('Incorrect code. Try again.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('router guards OTP URL and returns to login on cancel', (
    tester,
  ) async {
    final connectivity = ConnectivityCubit(LoginTestNetworkInfo());
    final bloc = loginBloc(
      connectivity,
      (options) async => reply(options, otpResponse),
    );
    final appRouter = AppRouter(authBloc: bloc);
    addTearDown(appRouter.dispose);
    addTearDown(bloc.close);
    addTearDown(connectivity.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: appRouter.router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    appRouter.router.go(Routes.loginOtp);
    await tester.pumpAndSettle();
    expect(
      appRouter.router.routeInformationProvider.value.uri.path,
      Routes.login,
    );
    bloc.add(
      LoginSubmitted(username: 'enforcer01', password: 'ExamplePass123'),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LoginOtpCard), findsOneWidget);
    expect(
      appRouter.router.routeInformationProvider.value.uri.path,
      Routes.loginOtp,
    );
    await tester.ensureVisible(find.text('Back to login'));
    await tester.tap(find.text('Back to login'));
    await tester.pumpAndSettle();
    expect(
      appRouter.router.routeInformationProvider.value.uri.path,
      Routes.login,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('expired code shows guidance without an expiry countdown', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: LoginOtpCard(
              state: LoginOtpPending(
                maskedEmail: 'e***@example.com',
                resendCooldownSeconds: 0,
                codeExpirySeconds: 0,
              ),
            ),
          ),
        ),
      ),
    );
    expect(
      find.text('This code has expired. Request a new code below.'),
      findsOneWidget,
    );
    expect(find.textContaining('Code expires in'), findsNothing);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
    expect(find.text('Resend code'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
