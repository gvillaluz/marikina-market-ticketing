import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/core/connectivity/cubit/connectivity_cubit.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:marikina_market_mobile/features/auth/presentation/widgets/login_card.dart';
import 'features/auth/login_mobile_flow_test.dart' show loginBloc;
import 'features/auth/login_test_network_info.dart';
import 'package:marikina_market_mobile/core/router/route_args.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/entities/account_lookup.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/widgets/recovery_code_card.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/otp_code_field.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/auth/presentation/widgets/login_btn.dart';
import 'package:marikina_market_mobile/features/auth/presentation/widgets/login_fields.dart';
import 'package:marikina_market_mobile/features/auth/presentation/widgets/login_otp_field.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/widgets/resend_text.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/bloc/password_recovery_bloc.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/bloc/password_recovery_event.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/bloc/password_recovery_state.dart';
import 'package:marikina_market_mobile/features/password_recovery/data/data_sources/password_recovery_remote_data_source.dart';
import 'package:marikina_market_mobile/features/password_recovery/data/repositories/password_recovery_repository_impl.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/use_cases/find_account_use_case.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/use_cases/send_otp_use_case.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/use_cases/verify_code_use_case.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/use_cases/reset_password_use_case.dart';
import 'features/auth/data/login_mobile_contract_test.dart'
    show contractClient, reply;

void main() {
  testWidgets(
    'forgot password with a username opens its named recovery route',
    (tester) async {
      final connectivity = ConnectivityCubit(LoginTestNetworkInfo());
      addTearDown(connectivity.close);
      final auth = loginBloc(
        connectivity,
        (options) async => reply(options, {}),
      );
      addTearDown(auth.close);
      await auth.stream.firstWhere((state) => state is Unauthenticated);
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/login',
            builder: (context, state) =>
                const Scaffold(body: SingleChildScrollView(child: LoginCard())),
          ),
          GoRoute(
            path: '/recovery/options',
            name: Routes.forgotPasswordOptionName,
            builder: (context, state) => Scaffold(
              body: Text(
                'Recover ${(state.extra as ForgotPasswordOptionArgs).username}',
              ),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        BlocProvider.value(
          value: auth,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'enforcer01');
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();
      expect(find.text('Recover enforcer01'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('recovery countdown changes only the resend subtree', (
    tester,
  ) async {
    final client = contractClient(
      (options) async => reply(options, {
        'message': 'Code sent.',
        'resend_cooldown_seconds': 30,
        'code_expiry_seconds': 600,
      }),
    );
    addTearDown(client.dio.close);
    final repository = PasswordRecoveryRepositoryImpl(
      PasswordRecoveryRemoteDataSourceImpl(client),
    );
    final bloc = PasswordRecoveryBloc(
      findAccountUseCase: FindAccountUseCase(repository),
      sendOtpUseCase: SendOtpUseCase(repository),
      verifyOtpUseCase: VerifyCodeUseCase(repository),
      resetPasswordUseCase: ResetPasswordUseCase(repository),
    );
    addTearDown(bloc.close);
    final sent = bloc.stream.firstWhere((state) => state is OtpSent);
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: RecoveryCodeCard(
                args: CodeValidationArgs(
                  username: 'enforcer01',
                  channel: 'email',
                  account: AccountLookup(
                    found: true,
                    maskedEmail: 'e***@example.com',
                    masketPhoneNumber: '***',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() => sent);
    await tester.pump();
    final field = tester.widget<OtpCodeField>(find.byType(OtpCodeField));
    expect(find.text('Resend in 00:30'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Resend in 00:29'), findsOneWidget);
    expect(
      identical(field, tester.widget<OtpCodeField>(find.byType(OtpCodeField))),
      isTrue,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  testWidgets('loading auth button retains label and respects reduced motion', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: AuthBtn(
              label: 'Verify',
              onPressed: () => taps++,
              isLoading: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Verify'), findsOneWidget);
    await tester.tap(find.byType(ElevatedButton));
    expect(taps, 0);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
  testWidgets('resend control wraps while sending and enforces cooldown', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(280, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var resends = 0;
    Future<void> showResend(bool sending, int cooldown) => tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(2),
            disableAnimations: true,
          ),
          child: Scaffold(
            body: ResendText(
              cooldownSeconds: cooldown,
              isSending: sending,
              onResend: () => resends++,
            ),
          ),
        ),
      ),
    );
    await showResend(true, 0);
    expect(tester.takeException(), isNull);
    await showResend(false, 30);
    await tester.tap(find.byType(TextButton));
    expect(resends, 0);
    await showResend(false, 0);
    await tester.tap(find.byType(TextButton));
    expect(resends, 1);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'login keyboard submit uses unchanged password and loading disables visibility',
    (tester) async {
      final username = TextEditingController();
      final password = TextEditingController(text: ' ExamplePass123 ');
      addTearDown(username.dispose);
      addTearDown(password.dispose);
      var submitted = 0;
      Future<void> showFields(bool enabled) => tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: LoginFields(
              usernameController: username,
              passwordController: password,
              enabled: enabled,
              onSubmitted: () => submitted++,
            ),
          ),
        ),
      );
      await showFields(true);
      await tester.showKeyboard(find.byType(TextField).last);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(submitted, 1);
      expect(password.text, ' ExamplePass123 ');
      await showFields(false);
      expect(
        tester.widget<IconButton>(find.byType(IconButton)).onPressed,
        isNull,
      );
    },
  );
  testWidgets('OTP entry fits actual card width at 280px', (tester) async {
    tester.view.physicalSize = const Size(280, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final code = TextEditingController();
    addTearDown(code.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(40),
            child: LoginOtpField(controller: code, enabled: true),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
  test('duplicate recovery operations use one pending request', () async {
    final requested = Completer<RequestOptions>();
    final pending = Completer<Response<Object?>>();
    var calls = 0;
    final client = contractClient((options) {
      calls++;
      requested.complete(options);
      return pending.future;
    });
    addTearDown(client.dio.close);
    final repository = PasswordRecoveryRepositoryImpl(
      PasswordRecoveryRemoteDataSourceImpl(client),
    );
    final bloc = PasswordRecoveryBloc(
      findAccountUseCase: FindAccountUseCase(repository),
      sendOtpUseCase: SendOtpUseCase(repository),
      verifyOtpUseCase: VerifyCodeUseCase(repository),
      resetPasswordUseCase: ResetPasswordUseCase(repository),
    );
    addTearDown(bloc.close);
    bloc.add(SendOtp(username: 'enforcer01', channel: 'email'));
    final options = await requested.future;
    bloc.add(SendOtp(username: 'enforcer01', channel: 'email'));
    await Future<void>.delayed(Duration.zero);
    expect(calls, 1);
    final failed = bloc.stream.firstWhere((state) => state is SendOtpFailed);
    pending.completeError(
      DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      ),
    );
    await failed;
  });
}
