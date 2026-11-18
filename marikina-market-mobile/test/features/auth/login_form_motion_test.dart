import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/connectivity/cubit/connectivity_cubit.dart';
import 'package:marikina_market_mobile/features/auth/data/models/user_model.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_state.dart';

import 'data/login_mobile_contract_test.dart'
    show otpResponse, profileResponse, reply;
import 'device_registration_test.dart' show accessToken;
import 'login_mobile_flow_test.dart' show loginBloc, startLogin;
import 'login_test_network_info.dart';

const hold = Duration(milliseconds: 300);
// Timers fire no earlier than asked; the margin only covers the moment the
// test starts its stopwatch after the tick state arrives.
const heldAtLeast = 250;

DioException refused(RequestOptions options, String message) => DioException(
  requestOptions: options,
  type: DioExceptionType.badResponse,
  response: Response<Object?>(
    requestOptions: options,
    statusCode: 400,
    data: {'message': message},
  ),
);

Future<Response<Object?>> loginServer(RequestOptions options) async {
  switch (options.path) {
    case '/auth/login-mobile':
      return reply(options, {...otpResponse, 'resend_cooldown_seconds': 0});
    case '/auth/verify-login-mobile':
      return reply(options, {
        'access_token': accessToken(),
        'refresh_token': 'synthetic-refresh',
        'refresh_token_expiration': '2099-01-01T00:00:00Z',
      });
    case '/user/me':
      return reply(options, profileResponse);
    default:
      return reply(options, {'message': 'ok'});
  }
}

AuthBloc newBloc(Future<Response<Object?>> Function(RequestOptions) server) {
  final connectivity = ConnectivityCubit(LoginTestNetworkInfo());
  addTearDown(connectivity.close);
  final bloc = loginBloc(connectivity, server);
  addTearDown(bloc.close);
  return bloc;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('Log in shows the tick for the hold before the code screen', () async {
    final bloc = newBloc(loginServer);
    await bloc.stream.firstWhere((s) => s is Unauthenticated);
    final ticked = bloc.stream.firstWhere(
      (s) => s is AuthLoginLoading && s.succeeded,
    );
    final pending = bloc.stream.firstWhere((s) => s is LoginOtpPending);
    bloc.add(
      LoginSubmitted(
        username: 'enforcer01',
        password: 'ExamplePass123',
        successHold: hold,
      ),
    );
    await ticked;
    final clock = Stopwatch()..start();
    await pending;
    expect(clock.elapsedMilliseconds, greaterThanOrEqualTo(heldAtLeast));
  });

  test('with no hold (animations removed) nothing waits or ticks', () async {
    final bloc = newBloc(loginServer);
    final seen = <AuthState>[];
    final sub = bloc.stream.listen(seen.add);
    addTearDown(sub.cancel);
    await startLogin(bloc);
    final authenticated = bloc.stream.firstWhere((s) => s is Authenticated);
    final clock = Stopwatch()..start();
    bloc.add(VerifyLoginSubmitted('001234'));
    await authenticated;
    expect(clock.elapsedMilliseconds, lessThan(heldAtLeast));
    expect(
      seen.whereType<AuthLoginLoading>().where((s) => s.succeeded),
      isEmpty,
    );
    expect(
      seen.whereType<LoginOtpPending>().where((s) => s.isVerified),
      isEmpty,
    );
  });

  test(
    'Verify and log in holds the green state, even across countdown ticks',
    () async {
      final bloc = newBloc(loginServer);
      await startLogin(bloc);
      final seen = <AuthState>[];
      final sub = bloc.stream.listen(seen.add);
      addTearDown(sub.cancel);
      final verified = bloc.stream.firstWhere(
        (s) => s is LoginOtpPending && s.isVerified,
      );
      final authenticated = bloc.stream.firstWhere((s) => s is Authenticated);
      // Longer than the 1-second countdown so at least one tick lands inside.
      const longHold = Duration(milliseconds: 1200);
      bloc.add(VerifyLoginSubmitted('001234', successHold: longHold));
      await verified;
      final clock = Stopwatch()..start();
      await authenticated;
      expect(clock.elapsedMilliseconds, greaterThanOrEqualTo(1150));
      final held = seen
          .skipWhile((s) => !(s is LoginOtpPending && s.isVerified))
          .takeWhile((s) => s is! Authenticated)
          .toList();
      expect(held.length, greaterThanOrEqualTo(2));
      expect(
        held.every((s) => s is LoginOtpPending && s.isVerified && s.isBusy),
        isTrue,
      );
    },
  );

  test('a rejected code is marked, and a new code clears the mark', () async {
    final bloc = newBloc((options) async {
      if (options.path == '/auth/verify-login-mobile') {
        throw refused(options, 'Invalid or expired code.');
      }
      return loginServer(options);
    });
    await startLogin(bloc);
    expect((bloc.state as LoginOtpPending).codeRejected, isFalse);
    final rejected = bloc.stream.firstWhere(
      (s) => s is LoginOtpPending && !s.isBusy && s.message != null,
    );
    bloc.add(VerifyLoginSubmitted('000000'));
    final afterWrong = await rejected as LoginOtpPending;
    expect(afterWrong.codeRejected, isTrue);
    expect(afterWrong.message, 'Invalid or expired code.');
    final resent = bloc.stream.firstWhere(
      (s) => s is LoginOtpPending && !s.isBusy && !s.requiresNewCode,
    );
    bloc.add(ResendLoginOtp());
    expect((await resent as LoginOtpPending).codeRejected, isFalse);
  });

  test('a lost connection is not marked as a wrong code', () async {
    final bloc = newBloc((options) async {
      if (options.path == '/auth/verify-login-mobile') {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      }
      return loginServer(options);
    });
    await startLogin(bloc);
    final failed = bloc.stream.firstWhere(
      (s) => s is LoginOtpPending && !s.isBusy && s.message != null,
    );
    bloc.add(VerifyLoginSubmitted('001234'));
    expect((await failed as LoginOtpPending).codeRejected, isFalse);
  });

  test('Save password holds the tick before leaving the screen', () async {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'test-access-token',
      'user_info_key': jsonEncode(
        UserModel.fromJson({
          ...profileResponse,
          'mustChangedPassword': true,
        }).toJson(),
      ),
    });
    final bloc = newBloc((options) async => reply(options, null));
    // Same start as change_password_flows_test 1.6.
    await bloc.stream.firstWhere((s) => s is Unauthenticated);
    final ticked = bloc.stream.firstWhere(
      (s) => s is AuthChangePasswordLoading && s.succeeded,
    );
    final done = bloc.stream.firstWhere((s) => s is Authenticated);
    bloc.add(
      ChangePasswordSubmitted(
        userId: 1,
        currentPassword: 'TempPass1',
        newPassword: 'NewPass123',
        confirmNewPassword: 'NewPass123',
        successHold: hold,
      ),
    );
    await ticked;
    final clock = Stopwatch()..start();
    final state = await done as Authenticated;
    expect(clock.elapsedMilliseconds, greaterThanOrEqualTo(heldAtLeast));
    expect(state.user.mustChangePassword, isFalse);
  });
}
