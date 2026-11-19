import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/router/route_args.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/password_recovery/data/data_sources/password_recovery_remote_data_source.dart';
import 'package:marikina_market_mobile/features/password_recovery/data/models/account_lookup_model.dart';
import 'package:marikina_market_mobile/features/password_recovery/data/repositories/password_recovery_repository_impl.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/use_cases/find_account_use_case.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/use_cases/reset_password_use_case.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/use_cases/send_otp_use_case.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/use_cases/verify_code_use_case.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/bloc/password_recovery_bloc.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/pages/forgot_password_option_page.dart';

import '../auth/data/login_mobile_contract_test.dart' show contractClient;

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  // The server's account lookup still includes a masked phone number; the
  // options page must offer only email and password even when it is present.
  final account = AccountLookupModel.fromJson({
    'found': true,
    'masked_email': 'e***@example.com',
    'masked_phone_number': '091****3309',
  }).toEntity();

  Future<void> pumpOptions(WidgetTester tester) async {
    // The page already has the account, so no request is expected.
    final client = contractClient(
      (options) async => throw StateError('Unexpected ${options.path}'),
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
    final router = GoRouter(
      initialLocation: '/options',
      routes: [
        GoRoute(
          path: '/options',
          builder: (context, state) => ForgotPasswordOptionPage(
            args: ForgotPasswordOptionArgs(
              username: 'enforcer01',
              account: account,
            ),
          ),
        ),
        GoRoute(
          path: '/code',
          name: Routes.codeVerificationName,
          builder: (context, state) => Scaffold(
            body: Text(
              'Code by ${(state.extra as CodeValidationArgs).channel}',
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(bloc.close);
    });
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('options page offers email and password, not SMS', (
    tester,
  ) async {
    await pumpOptions(tester);
    expect(find.text('Step 2 of 4'), findsOneWidget);
    expect(find.text('Reset via Email'), findsOneWidget);
    expect(find.text('Continue with password'), findsOneWidget);
    expect(find.text('Reset via SMS number'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('choosing email opens the code page for email', (tester) async {
    await pumpOptions(tester);
    await tester.tap(find.text('Reset via Email'));
    await tester.pumpAndSettle();
    expect(find.text('Code by email'), findsOneWidget);
  });

  testWidgets('option icons are outline icons, like the other login screens', (
    tester,
  ) async {
    await pumpOptions(tester);
    expect(find.byIcon(Icons.email), findsNothing);
    expect(find.byIcon(Icons.lock), findsNothing);
    expect(find.byIcon(Icons.email_outlined), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
  });
}
