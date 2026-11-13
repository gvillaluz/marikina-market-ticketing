import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/network/client.dart';
import 'package:marikina_market_mobile/core/router/route_args.dart';
import 'package:marikina_market_mobile/features/password_recovery/data/data_sources/password_recovery_remote_data_source.dart';
import 'package:marikina_market_mobile/features/password_recovery/data/repositories/password_recovery_repository_impl.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/use_cases/find_account_use_case.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/use_cases/reset_password_use_case.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/use_cases/send_otp_use_case.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/use_cases/verify_code_use_case.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/bloc/password_recovery_bloc.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/bloc/password_recovery_event.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/bloc/password_recovery_state.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/pages/reset_password_page.dart';

import '../auth/data/login_mobile_contract_test.dart'
    show contractClient, reply;

const rule = 'Use at least 8 characters, with a number and a capital letter.';
const expired = 'Your reset session has expired. Please start again.';

class Server {
  final requests = <Map<String, Object?>>[];
  final Future<Response<Object?>> Function(RequestOptions) answer;
  Server(this.answer);

  late final ApiClient client = contractClient((options) {
    requests.add(Map<String, Object?>.from(options.data as Map));
    return answer(options);
  });

  PasswordRecoveryBloc bloc() {
    final repository = PasswordRecoveryRepositoryImpl(
      PasswordRecoveryRemoteDataSourceImpl(client),
    );
    return PasswordRecoveryBloc(
      findAccountUseCase: FindAccountUseCase(repository),
      sendOtpUseCase: SendOtpUseCase(repository),
      verifyOtpUseCase: VerifyCodeUseCase(repository),
      resetPasswordUseCase: ResetPasswordUseCase(repository),
    );
  }
}

Future<Response<Object?>> succeeds(RequestOptions o) async =>
    reply(o, {'success': true, 'message': 'Password reset successfully.'});

Future<Response<Object?>> refuses(RequestOptions o, int status, Object body) =>
    Future.error(
      DioException(
        requestOptions: o,
        type: DioExceptionType.badResponse,
        response: Response<Object?>(
          requestOptions: o,
          statusCode: status,
          data: body,
        ),
      ),
    );

Future<PasswordRecoveryState> reset(
  PasswordRecoveryBloc bloc,
  String password,
  String confirm,
) async {
  final states = <PasswordRecoveryState>[];
  final sub = bloc.stream.listen(states.add);
  bloc.add(ResetPassword('vendor01', password, confirm, 'synthetic-reset'));
  await Future<void>.delayed(const Duration(milliseconds: 200));
  await sub.cancel();
  return states.last;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('a password with no capital letter is refused and not sent', () async {
    final server = Server(succeeds);
    final state = await reset(server.bloc(), 'abcdefg1', 'abcdefg1');
    expect(state, isA<ResetPasswordFailed>());
    expect((state as ResetPasswordFailed).message, rule);
    expect(server.requests, isEmpty);
  });

  test('boxes that do not match are refused and not sent', () async {
    final server = Server(succeeds);
    final bloc = server.bloc();
    final state = await reset(bloc, 'Abcdefg1', 'Abcdefg2');
    expect(state, isA<ResetPasswordFailed>());
    expect((state as ResetPasswordFailed).message, 'Passwords do not match.');
    expect(server.requests, isEmpty);
    // the button works again: a correct retry is sent
    final retry = await reset(bloc, 'Abcdefg1', 'Abcdefg1');
    expect(retry, isA<ResetPasswordSuccessfully>());
    expect(server.requests, hasLength(1));
  });

  test('an empty confirmation asks to confirm and is not sent', () async {
    final server = Server(succeeds);
    final state = await reset(server.bloc(), 'Abcdefg1', '');
    expect(
      (state as ResetPasswordFailed).message,
      'Confirm your new password.',
    );
    expect(server.requests, isEmpty);
  });

  test('a password with spaces is sent exactly as typed', () async {
    final server = Server(succeeds);
    await reset(server.bloc(), '  Abcdefg1', '  Abcdefg1');
    expect(server.requests.single['new_password'], '  Abcdefg1');
  });

  test('server success goes on to sign-in', () async {
    final server = Server(succeeds);
    final state = await reset(server.bloc(), 'Abcdefg1', 'Abcdefg1');
    expect((state as ResetPasswordSuccessfully).result.success, isTrue);
  });

  test('expired session text from the server is shown', () async {
    final server = Server(
      (o) async => reply(o, {'success': false, 'message': expired}),
    );
    final state = await reset(server.bloc(), 'Abcdefg1', 'Abcdefg1');
    expect(state, isA<ResetPasswordFailed>());
    expect((state as ResetPasswordFailed).message, expired);
  });

  test('a 400 shows the server text, not a generic message', () async {
    final server = Server(
      (o) => refuses(o, 400, {
        'errors': {
          'NewPassword': [rule],
        },
      }),
    );
    final state = await reset(server.bloc(), 'Abcdefg1', 'Abcdefg1');
    expect(state, isA<ResetPasswordFailed>());
    expect((state as ResetPasswordFailed).message, rule);
  });

  testWidgets('the page shows the real rule and keeps spaces as typed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    // A refusal keeps the page on screen (a success would navigate to sign-in,
    // which needs a router this test does not have).
    final server = Server(
      (o) async => reply(o, {'success': false, 'message': expired}),
    );
    late PasswordRecoveryBloc bloc;
    await tester.runAsync(() async => bloc = server.bloc());
    addTearDown(() => unawaited(bloc.close()));
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          home: ResetPasswordPage(
            args: ResetPasswordArgs(
              username: 'vendor01',
              resetToken: 'synthetic-reset',
            ),
          ),
        ),
      ),
    );
    expect(
      find.text('At least 8 characters, with a number and a capital letter.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField).at(0), '  Abcdefg1');
    await tester.enterText(find.byType(TextField).at(1), '  Abcdefg1');
    final submit = find.text('Change Password');
    await tester.ensureVisible(submit);
    await tester.runAsync(() async {
      final done = bloc.stream.firstWhere(
        (state) => state is ResetPasswordFailed,
      );
      await tester.tap(submit);
      await done;
    });
    expect(server.requests.single['new_password'], '  Abcdefg1');
  });
}
