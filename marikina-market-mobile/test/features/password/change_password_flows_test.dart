import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/connectivity/cubit/connectivity_cubit.dart';
import 'package:marikina_market_mobile/core/network/client.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/utils/password_change_check.dart';
import 'package:marikina_market_mobile/features/auth/data/models/user_model.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:marikina_market_mobile/features/auth/presentation/widgets/change_password_card.dart'
    as forced;
import 'package:marikina_market_mobile/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:marikina_market_mobile/features/profile/presentation/bloc/profile_event.dart';
import 'package:marikina_market_mobile/features/profile/presentation/bloc/profile_state.dart';
import 'package:marikina_market_mobile/features/profile/presentation/pages/change_password_page.dart';

import '../auth/data/login_mobile_contract_test.dart'
    show contractClient, profileResponse, reply;
import '../auth/login_mobile_flow_test.dart' show loginBloc;
import '../auth/login_test_network_info.dart';
import '../profile/profile_form_test.dart' show formBloc;

const wrongPassword = <String, Object?>{
  'code': 'PASSWORD_CHANGE_FAILED',
  'message': 'Incorrect password.',
};
const weakPassword = <String, Object?>{
  'errors': {
    'NewPassword': ['Password must contain an uppercase letter.'],
  },
};

DioException rejected(RequestOptions options, Object? body) => DioException(
  requestOptions: options,
  type: DioExceptionType.badResponse,
  response: Response<Object?>(
    requestOptions: options,
    statusCode: 400,
    data: body,
  ),
);

UpdatePasswordSubmitted profileSubmit() => UpdatePasswordSubmitted(
  userId: 1,
  currentPassword: 'WrongPass1',
  newPassword: 'NewPass123',
  confirmNewPassword: 'NewPass123',
);

ChangePasswordSubmitted forcedSubmit() => ChangePasswordSubmitted(
  userId: 1,
  currentPassword: 'WrongPass1',
  newPassword: 'NewPass123',
  confirmNewPassword: 'NewPass123',
);

Future<AuthBloc> readyForcedBloc(
  ConnectivityCubit connectivity,
  Future<Response<Object?>> Function(RequestOptions) respond,
) async {
  final bloc = loginBloc(connectivity, respond);
  addTearDown(bloc.close);
  await bloc.stream
      .firstWhere((s) => s is Unauthenticated)
      .timeout(const Duration(seconds: 5));
  return bloc;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => FlutterSecureStorage.setMockInitialValues({
      'access_token': 'test-access-token',
    }),
  );

  group('normal change (profile)', () {
    test('1.1 wrong current password shows the server message', () async {
      final client = contractClient((options) async {
        expect(options.path, '/auth/change-password');
        throw rejected(options, wrongPassword);
      });
      addTearDown(client.dio.close);
      final bloc = formBloc(client);
      addTearDown(bloc.close);
      final done = bloc.stream.firstWhere((s) => s is! ChangePasswordLoading);
      bloc.add(profileSubmit());
      final state = await done.timeout(const Duration(seconds: 5));
      expect(state, isA<ChangePasswordError>());
      expect((state as ChangePasswordError).message, 'Incorrect password.');
    });

    test('1.2 form-rule rejection shows the rule text', () async {
      final client = contractClient((options) async {
        throw rejected(options, weakPassword);
      });
      addTearDown(client.dio.close);
      final bloc = formBloc(client);
      addTearDown(bloc.close);
      final done = bloc.stream.firstWhere((s) => s is! ChangePasswordLoading);
      bloc.add(profileSubmit());
      final state = await done.timeout(const Duration(seconds: 5));
      expect(state, isA<ChangePasswordError>());
      expect(
        (state as ChangePasswordError).message,
        'Password must contain an uppercase letter.',
      );
    });

    test('1.6 success ends in PasswordChangedSuccessfully', () async {
      final client = contractClient((options) async => reply(options, null));
      addTearDown(client.dio.close);
      final bloc = formBloc(client);
      addTearDown(bloc.close);
      final done = bloc.stream.firstWhere((s) => s is! ChangePasswordLoading);
      bloc.add(profileSubmit());
      expect(
        await done.timeout(const Duration(seconds: 5)),
        isA<PasswordChangedSuccessfully>(),
      );
    });
  });

  group('forced change (auth)', () {
    test('1.3 wrong current password stays with the message', () async {
      final connectivity = ConnectivityCubit(LoginTestNetworkInfo());
      addTearDown(connectivity.close);
      final bloc = await readyForcedBloc(connectivity, (options) async {
        expect(options.path, '/auth/mandatory-change-password');
        throw rejected(options, wrongPassword);
      });
      final seen = <AuthState>[];
      final sub = bloc.stream.listen(seen.add);
      addTearDown(sub.cancel);
      final done = bloc.stream.firstWhere(
        (s) => s is! AuthChangePasswordLoading,
      );
      bloc.add(forcedSubmit());
      final state = await done.timeout(const Duration(seconds: 5));
      expect(state, isA<AuthChangePasswordError>());
      expect((state as AuthChangePasswordError).message, 'Incorrect password.');
      expect(seen.whereType<Unauthenticated>(), isEmpty);
    });

    test('1.6 success becomes Authenticated with no required change', () async {
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'test-access-token',
        'user_info_key': jsonEncode(
          UserModel.fromJson({
            ...profileResponse,
            'mustChangedPassword': true,
          }).toJson(),
        ),
      });
      final connectivity = ConnectivityCubit(LoginTestNetworkInfo());
      addTearDown(connectivity.close);
      final bloc = await readyForcedBloc(connectivity, (options) async {
        expect(options.path, '/auth/mandatory-change-password');
        return reply(options, null);
      });
      final done = bloc.stream.firstWhere(
        (s) => s is! AuthChangePasswordLoading,
      );
      bloc.add(forcedSubmit());
      final state = await done.timeout(const Duration(seconds: 5));
      expect(state, isA<Authenticated>());
      expect((state as Authenticated).user.mustChangePassword, isFalse);
    });
  });

  // Each case: new password typed, confirmation typed, the message the screen
  // must show (null for none), and how many requests must reach the fake.
  // The use cases also refuse a mismatch, so only the weak-password case
  // (valid for the use case, invalid for the screen rule) proves the screen
  // itself stops the request. The matching case is the control that proves a
  // request would be seen here at all.
  const cases = {
    'a mismatch sends nothing': (
      'NewPass123',
      'NewPass124',
      'Passwords do not match.',
      0,
    ),
    'a password without a capital letter sends nothing': (
      'abcdefg1',
      'abcdefg1',
      'Use at least 8 characters, with a number and a capital letter.',
      0,
    ),
    'matching valid values send one request': (
      'NewPass123',
      'NewPass123',
      null,
      1,
    ),
  };

  // Starts listening before the tap. Resolves when the bloc reaches the
  // rejected state (the request went out and the fake refused it), or after
  // one second of silence (nothing was sent).
  Future<bool?>? listenForRequest<S>(
    WidgetTester tester,
    Stream<S> states,
    bool Function(S) rejectedState,
  ) => tester.runAsync(
    () => states
        .timeout(const Duration(seconds: 1), onTimeout: (sink) => sink.close())
        .any(rejectedState),
  );

  group('1.5 checks before sending', () {
    for (final MapEntry(
          key: name,
          value: (newPassword, confirm, message, expected),
        )
        in cases.entries) {
      testWidgets('profile screen: $name', (tester) async {
        var requests = 0;
        late ApiClient client;
        late ProfileBloc bloc;
        await tester.runAsync(() async {
          client = contractClient((options) async {
            requests++;
            throw rejected(options, wrongPassword);
          });
          bloc = formBloc(client);
        });
        addTearDown(client.dio.close);
        addTearDown(bloc.close);
        await tester.pumpWidget(
          BlocProvider<ProfileBloc>.value(
            value: bloc,
            child: MaterialApp(
              theme: AppTheme.light,
              home: ChangePasswordPage(
                user: UserModel.fromJson(profileResponse).toEntity(),
              ),
            ),
          ),
        );
        await tester.enterText(find.byType(TextField).at(0), 'OldPass123');
        await tester.enterText(find.byType(TextField).at(1), newPassword);
        await tester.enterText(find.byType(TextField).at(2), confirm);
        await tester.ensureVisible(find.text('Save Changes'));
        final sent = listenForRequest(
          tester,
          bloc.stream,
          (s) => s is ChangePasswordError,
        );
        await tester.tap(find.text('Save Changes'));
        expect(await sent, expected == 1);
        await tester.pump();
        expect(
          find.text(message ?? 'no message expected'),
          message == null ? findsNothing : findsOneWidget,
        );
        expect(find.text(PasswordChangeCheck.hint), findsOneWidget);
        expect(requests, expected);
      });

      testWidgets('forced screen: $name', (tester) async {
        var requests = 0;
        late ConnectivityCubit connectivity;
        late AuthBloc auth;
        await tester.runAsync(() async {
          connectivity = ConnectivityCubit(LoginTestNetworkInfo());
          auth = loginBloc(connectivity, (options) async {
            requests++;
            throw rejected(options, wrongPassword);
          });
          await auth.stream
              .firstWhere((s) => s is Unauthenticated)
              .timeout(const Duration(seconds: 5));
        });
        addTearDown(connectivity.close);
        addTearDown(auth.close);
        await tester.pumpWidget(
          BlocProvider<AuthBloc>.value(
            value: auth,
            child: MaterialApp(
              theme: AppTheme.light,
              home: const Scaffold(
                body: SingleChildScrollView(child: forced.ChangePasswordCard()),
              ),
            ),
          ),
        );
        await tester.enterText(find.byType(TextField).at(0), 'OldPass123');
        await tester.enterText(find.byType(TextField).at(1), newPassword);
        await tester.enterText(find.byType(TextField).at(2), confirm);
        await tester.ensureVisible(find.text('SAVE PASSWORD'));
        final sent = listenForRequest(
          tester,
          auth.stream,
          (s) => s is AuthChangePasswordError,
        );
        await tester.tap(find.text('SAVE PASSWORD'));
        expect(await sent, expected == 1);
        await tester.pump();
        expect(
          find.text(message ?? 'no message expected'),
          message == null ? findsNothing : findsOneWidget,
        );
        expect(find.text(PasswordChangeCheck.hint), findsOneWidget);
        expect(requests, expected);
      });
    }
  });

  group('forced screen look', () {
    late ConnectivityCubit connectivity;
    late AuthBloc auth;
    var requests = 0;

    Future<void> pumpForced(WidgetTester tester) async {
      requests = 0;
      await tester.runAsync(() async {
        connectivity = ConnectivityCubit(LoginTestNetworkInfo());
        auth = loginBloc(connectivity, (options) async {
          requests++;
          throw rejected(options, wrongPassword);
        });
        await auth.stream
            .firstWhere((s) => s is Unauthenticated)
            .timeout(const Duration(seconds: 5));
      });
      addTearDown(connectivity.close);
      addTearDown(auth.close);
      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: auth,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(
              body: SingleChildScrollView(child: forced.ChangePasswordCard()),
            ),
          ),
        ),
      );
    }

    testWidgets('shows the title and the explanation line', (tester) async {
      await pumpForced(tester);
      expect(find.text('CHANGE PASSWORD'), findsOneWidget);
      expect(
        find.text(
          'For your security, change the temporary password you were given '
          'before you continue.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('the button says SAVE PASSWORD', (tester) async {
      await pumpForced(tester);
      expect(find.text('SAVE PASSWORD'), findsOneWidget);
      expect(find.text('UPDATE PASSWORD'), findsNothing);
    });

    testWidgets('a server error shows below the button', (tester) async {
      await pumpForced(tester);
      await tester.enterText(find.byType(TextField).at(0), 'OldPass123');
      await tester.enterText(find.byType(TextField).at(1), 'NewPass123');
      await tester.enterText(find.byType(TextField).at(2), 'NewPass123');
      await tester.ensureVisible(find.text('SAVE PASSWORD'));
      final sent = listenForRequest(
        tester,
        auth.stream,
        (s) => s is AuthChangePasswordError,
      );
      await tester.tap(find.text('SAVE PASSWORD'));
      expect(await sent, isTrue);
      await tester.pump();
      expect(
        tester.getTopLeft(find.text('Incorrect password.')).dy,
        greaterThan(tester.getBottomLeft(find.text('SAVE PASSWORD')).dy),
      );
    });

    testWidgets('Next moves from each field to the next field', (tester) async {
      await pumpForced(tester);
      bool hasFocus(int i) => tester
          .widget<EditableText>(find.byType(EditableText).at(i))
          .focusNode
          .hasFocus;
      await tester.tap(find.byType(TextField).at(0));
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      expect(hasFocus(1), isTrue);
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      expect(hasFocus(2), isTrue);
    });

    testWidgets('Done on the last field sends the change', (tester) async {
      await pumpForced(tester);
      await tester.enterText(find.byType(TextField).at(0), 'OldPass123');
      await tester.enterText(find.byType(TextField).at(1), 'NewPass123');
      await tester.enterText(find.byType(TextField).at(2), 'NewPass123');
      final sent = listenForRequest(
        tester,
        auth.stream,
        (s) => s is AuthChangePasswordError,
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(await sent, isTrue);
      expect(requests, 1);
    });
  });
}
