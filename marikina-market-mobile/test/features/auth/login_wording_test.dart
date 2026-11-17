import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/connectivity/cubit/connectivity_cubit.dart';
import 'package:marikina_market_mobile/core/errors/exceptions.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/network/client.dart';
import 'package:marikina_market_mobile/core/storage/secure_storage_service_impl.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/auth/data/data_sources/auth_local_data_source.dart';
import 'package:marikina_market_mobile/features/auth/data/models/user_model.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/check_auth_status_use_case.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/login_user_use_case.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/logout_user_use_case.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/mandatory_change_password_use_case.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/refresh_tokens_use_case.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/register_device_token_use_case.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/sync_pending_logouts_use_case.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/verify_login_use_case.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:marikina_market_mobile/features/auth/presentation/pages/login_otp_page.dart';
import 'package:marikina_market_mobile/features/auth/presentation/widgets/change_password_card.dart'
    as forced;
import 'package:marikina_market_mobile/features/auth/presentation/widgets/login_card.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/widgets/back_to_login_button.dart';
import 'package:marikina_market_mobile/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:marikina_market_mobile/features/profile/presentation/pages/change_password_page.dart';
import 'package:marikina_market_mobile/features/profile/presentation/bloc/profile_state.dart';

import '../password/password_rule_checklist_test.dart' show pumpResetScreen;
import '../profile/profile_form_test.dart' show formBloc;
import 'data/login_mobile_contract_test.dart'
    show
        contractClient,
        contractRepository,
        otpResponse,
        profileResponse,
        reply;
import 'data/logout_contract_test.dart' show logoutRepository, session;
import 'login_mobile_flow_test.dart' show loginBloc;
import 'login_test_network_info.dart';
import 'logout_test_network_info.dart';

/// Any text on screen that says "sign in", "sign-in" or "signing in",
/// except the code page heading, which this slice keeps on purpose.
final signInText = find.byWidgetPredicate((widget) {
  if (widget is! RichText) return false;
  final text = widget.text.toPlainText();
  return text != 'SIGN-IN VERIFICATION' &&
      RegExp(r'sign(ing)?[ -]?in', caseSensitive: false).hasMatch(text);
});

DioException refusedWithoutMessage(RequestOptions options) => DioException(
  requestOptions: options,
  type: DioExceptionType.badResponse,
  response: Response<Object?>(requestOptions: options, statusCode: 400),
);

Future<AuthBloc> readyBloc(
  WidgetTester tester,
  Future<Response<Object?>> Function(RequestOptions) respond,
) async {
  late ConnectivityCubit connectivity;
  late AuthBloc bloc;
  await tester.runAsync(() async {
    connectivity = ConnectivityCubit(LoginTestNetworkInfo());
    bloc = loginBloc(connectivity, respond);
    await bloc.stream
        .firstWhere((s) => s is Unauthenticated)
        .timeout(const Duration(seconds: 5));
  });
  addTearDown(connectivity.close);
  addTearDown(bloc.close);
  return bloc;
}

Widget screen(AuthBloc bloc, Widget child) => BlocProvider<AuthBloc>.value(
  value: bloc,
  child: MaterialApp(theme: AppTheme.light, home: child),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('screens', () {
    testWidgets('login: the button says Log in', (tester) async {
      final bloc = await readyBloc(tester, (o) async => reply(o, otpResponse));
      await tester.pumpWidget(
        screen(
          bloc,
          const Scaffold(body: SingleChildScrollView(child: LoginCard())),
        ),
      );
      expect(find.text('Log in'), findsOneWidget);
      expect(find.text('LOGIN'), findsNothing);
      expect(signInText, findsNothing);
    });

    testWidgets('login: the expired-session note says log in again', (
      tester,
    ) async {
      FlutterSecureStorage.setMockInitialValues({...session});
      final bloc = await readyBloc(
        tester,
        (o) async => reply(o, {'message': 'Logout confirmed.'}),
      );
      await tester.pumpWidget(
        screen(
          bloc,
          const Scaffold(body: SingleChildScrollView(child: LoginCard())),
        ),
      );
      await tester.runAsync(() async {
        final expired = bloc.stream.firstWhere(
          (s) => s is Unauthenticated && s.sessionExpired,
        );
        bloc.add(LogoutUser(true));
        await expired.timeout(const Duration(seconds: 5));
      });
      await tester.pump();
      expect(
        find.text('Your session has expired. Please log in again.'),
        findsOneWidget,
      );
      expect(signInText, findsNothing);
    });

    testWidgets('code page: button, text and back link say log in', (
      tester,
    ) async {
      final bloc = await readyBloc(tester, (o) async => reply(o, otpResponse));
      await tester.runAsync(() async {
        final pending = bloc.stream.firstWhere((s) => s is LoginOtpPending);
        bloc.add(
          LoginSubmitted(username: 'enforcer01', password: 'ExamplePass123'),
        );
        await pending.timeout(const Duration(seconds: 5));
      });
      await tester.pumpWidget(screen(bloc, const LoginOtpPage()));
      expect(find.text('Verify and log in'), findsOneWidget);
      expect(
        find.text(
          'Enter the 6-digit code sent to e***@example.com to finish logging in.',
        ),
        findsOneWidget,
      );
      expect(find.text('Back to log in'), findsOneWidget);
      expect(find.text('SIGN-IN VERIFICATION'), findsOneWidget);
      expect(signInText, findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('change password: the button says Save password', (
      tester,
    ) async {
      final bloc = await readyBloc(tester, (o) async => reply(o, otpResponse));
      await tester.pumpWidget(
        screen(
          bloc,
          const Scaffold(
            body: SingleChildScrollView(child: forced.ChangePasswordCard()),
          ),
        ),
      );
      expect(find.text('Save password'), findsOneWidget);
      expect(find.text('SAVE PASSWORD'), findsNothing);
      expect(signInText, findsNothing);
    });

    testWidgets('forgot password: the shared back link says Back to log in', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: BackToLoginButton())),
      );
      expect(find.text('Back to log in'), findsOneWidget);
      expect(find.text('Back to login'), findsNothing);
    });

    testWidgets('create a new password: no sign-in words', (tester) async {
      await pumpResetScreen(tester);
      expect(find.text('Back to log in'), findsOneWidget);
      expect(signInText, findsNothing);
    });
  });

  group('messages', () {
    test('a refused login with no server text says log in', () async {
      final client = contractClient(
        (options) async => throw refusedWithoutMessage(options),
      );
      addTearDown(client.dio.close);
      final result = await contractRepository(
        client,
      ).loginUser('enforcer01', 'ExamplePass123');
      expect(
        (result as ResultFailure).failure.message,
        'Unable to log in. Please check your details and try again.',
      );
    });

    test('an unreadable saved profile says log in again', () async {
      FlutterSecureStorage.setMockInitialValues({'user_info_key': 'not json'});
      final local = AuthLocalDataSourceImpl(
        storageService: const SecureStorageServiceImpl(
          storage: FlutterSecureStorage(),
        ),
      );
      await expectLater(
        local.getUser(),
        throwsA(
          isA<CacheException>().having(
            (e) => e.message,
            'message',
            'Unable to read your saved profile. Please log in again.',
          ),
        ),
      );
    });

    test('an expired session says log in again', () async {
      FlutterSecureStorage.setMockInitialValues({
        ...session,
        'refresh_expiration': '2020-01-01T00:00:00Z',
      });
      final client = contractClient(
        (options) async => throw StateError('nothing should be sent'),
      );
      addTearDown(client.dio.close);
      final result = await contractRepository(client).refreshTokens();
      expect(
        (result as ResultFailure).failure.message,
        'Session expired. Please log in again.',
      );
    });

    test(
      'a rejected pending logout with no server text says log in again',
      () async {
        FlutterSecureStorage.setMockInitialValues({...session});
        final client = contractClient(
          (options) async => throw refusedWithoutMessage(options),
        );
        addTearDown(client.dio.close);
        final network = LogoutTestNetworkInfo(online: false);
        // Offline, so the logout is queued for later.
        await logoutRepository(client, network).logoutUser();
        network.online = true;
        final repository = logoutRepository(client, network);
        final connectivity = ConnectivityCubit(network);
        addTearDown(connectivity.close);
        final bloc = AuthBloc(
          connectivityCubit: connectivity,
          checkAuthStatusUseCase: CheckAuthStatusUseCase(repository),
          loginUserUseCase: LoginUserUseCase(repository),
          verifyLoginUseCase: VerifyLoginUseCase(repository),
          logoutUserUseCase: LogoutUserUseCase(repository),
          mandatoryChangePasswordUseCase: MandatoryChangePasswordUseCase(
            repository,
          ),
          refreshTokensUseCase: RefreshTokensUseCase(repository),
          registerDeviceTokenUseCase: RegisterDeviceTokenUseCase(repository),
          syncPendingLogoutsUseCase: SyncPendingLogoutsUseCase(repository),
        );
        addTearDown(bloc.close);
        final error = await bloc.stream
            .firstWhere((s) => s is AuthConnectionError)
            .timeout(const Duration(seconds: 5));
        expect(
          (error as AuthConnectionError).message,
          'A pending logout request was rejected. Please log in again.',
        );
      },
    );

    testWidgets('the note after a profile password change says log in again', (
      tester,
    ) async {
      final auth = await readyBloc(
        tester,
        (o) async => reply(o, {'message': 'Logout confirmed.'}),
      );
      late ApiClient client;
      late ProfileBloc profile;
      await tester.runAsync(() async {
        client = contractClient((options) async => reply(options, null));
        profile = formBloc(client);
      });
      addTearDown(client.dio.close);
      addTearDown(profile.close);
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: auth),
            BlocProvider<ProfileBloc>.value(value: profile),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: ChangePasswordPage(
              user: UserModel.fromJson(profileResponse).toEntity(),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField).at(0), 'OldPass123');
      await tester.enterText(find.byType(TextField).at(1), 'NewPass123');
      await tester.enterText(find.byType(TextField).at(2), 'NewPass123');
      await tester.ensureVisible(find.text('Save Changes'));
      await tester.runAsync(() async {
        final done = profile.stream.firstWhere(
          (s) => s is! ChangePasswordLoading,
        );
        await tester.tap(find.text('Save Changes'));
        await done.timeout(const Duration(seconds: 5));
      });
      await tester.pump();
      expect(
        find.text('Password successfully changed. Please log in again.'),
        findsOneWidget,
      );
    });
  });
}
