import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/network/client.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/auth/data/models/user_model.dart';
import 'package:marikina_market_mobile/features/profile/domain/use_cases/change_password_use_case.dart';
import 'package:marikina_market_mobile/features/profile/domain/use_cases/change_profile_photo_use_case.dart';
import 'package:marikina_market_mobile/features/profile/domain/use_cases/edit_profile_use_case.dart';
import 'package:marikina_market_mobile/features/profile/domain/use_cases/remove_profile_photo_use_case.dart';
import 'package:marikina_market_mobile/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:marikina_market_mobile/features/profile/presentation/bloc/profile_state.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/edit_profile_card.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/profile_detail_row.dart';

import '../auth/data/login_mobile_contract_test.dart'
    show contractClient, reply;
import 'profile_contract_test.dart' show profileRepository, profileResponse;

ProfileBloc formBloc(ApiClient client) {
  final repository = profileRepository(client);
  return ProfileBloc(
    editProfileUseCase: EditProfileUseCase(repository),
    changePasswordUseCase: ChangePasswordUseCase(repository),
    changeProfilePhotoUseCase: ChangeProfilePhotoUseCase(repository),
    removeProfilePhotoUseCase: RemoveProfilePhotoUseCase(repository),
  );
}

Future<void> showForm(
  WidgetTester tester,
  ProfileBloc bloc, {
  Map<String, Object?> response = profileResponse,
}) => tester.pumpWidget(
  BlocProvider.value(
    value: bloc,
    child: MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SingleChildScrollView(
          padding: AppTheme.profilePagePadding,
          child: EditProfileCard(user: UserModel.fromJson(response).toEntity()),
        ),
      ),
    ),
  ),
);

void main() {
  setUp(
    () => FlutterSecureStorage.setMockInitialValues({
      'access_token': 'test-access-token',
    }),
  );

  testWidgets(
    'prefills every field and displays server error without losing input at 320px',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 220);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      Map<String, Object?>? payload;
      final client = contractClient((options) async {
        payload = options.data as Map<String, Object?>;
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response<Object?>(
            requestOptions: options,
            statusCode: 400,
            data: {'message': 'Email is already in use.'},
          ),
        );
      });
      final bloc = formBloc(client);
      addTearDown(client.dio.close);
      addTearDown(bloc.close);
      await showForm(tester, bloc);
      for (final entry in {
        'FIRST NAME': 'Juan',
        'MIDDLE NAME (OPTIONAL)': 'Santos',
        'LAST NAME': 'Dela Cruz',
        'DATE OF BIRTH': '1995-06-15',
        'EMAIL': 'juan@example.com',
        'PHONE NUMBER': '09171234567',
        'HOUSE NUMBER': '123',
        'STREET': 'J.P. Rizal',
        'BARANGAY': 'Sta. Elena',
        'CITY': 'Marikina',
      }.entries) {
        final field = tester.widget<TextFormField>(
          find.byKey(ValueKey(entry.key)),
        );
        expect(field.controller!.text, entry.value);
      }
      await tester.ensureVisible(find.byKey(const ValueKey('EMAIL')));
      await tester.enterText(
        find.byKey(const ValueKey('EMAIL')),
        'updated@example.com',
      );
      await tester.ensureVisible(find.text('SAVE CHANGES'));
      await tester.tap(find.text('SAVE CHANGES'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.text('Email is already in use.'), findsOneWidget);
      expect(payload!['email'], 'updated@example.com');
      expect(payload!['user_id'], isNull);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('EMAIL')))
            .controller!
            .text,
        'updated@example.com',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('future birth date and invalid phone block saving', (
    tester,
  ) async {
    var requests = 0;
    final client = contractClient((options) async {
      requests++;
      return reply(options, profileResponse);
    });
    final bloc = formBloc(client);
    addTearDown(client.dio.close);
    addTearDown(bloc.close);
    await showForm(
      tester,
      bloc,
      response: {
        ...profileResponse,
        'dateOfBirth': '2099-01-01',
        'phoneNumber': '08171234567',
      },
    );
    await tester.ensureVisible(find.text('SAVE CHANGES'));
    await tester.tap(find.text('SAVE CHANGES'));
    await tester.pump();
    expect(find.text('Birth date cannot be in the future.'), findsOneWidget);
    expect(find.text('Use 11 digits starting with 09.'), findsOneWidget);
    expect(requests, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('required address and overlong name block saving', (
    tester,
  ) async {
    var requests = 0;
    final client = contractClient((options) async {
      requests++;
      return reply(options, profileResponse);
    });
    final bloc = formBloc(client);
    addTearDown(client.dio.close);
    addTearDown(bloc.close);
    await showForm(tester, bloc);
    await tester.enterText(find.byKey(const ValueKey('FIRST NAME')), 'a' * 101);
    await tester.ensureVisible(find.byKey(const ValueKey('HOUSE NUMBER')));
    await tester.enterText(find.byKey(const ValueKey('HOUSE NUMBER')), '   ');
    await tester.ensureVisible(find.text('SAVE CHANGES'));
    await tester.tap(find.text('SAVE CHANGES'));
    await tester.pump();
    expect(find.text('Use at most 100 characters.'), findsOneWidget);
    expect(find.text('This field is required.'), findsOneWidget);
    expect(requests, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'empty optional middle name submits null and duplicate saves are disabled',
    (tester) async {
      var requests = 0;
      final response = Completer<Response<Object?>>();
      RequestOptions? requestOptions;
      final client = contractClient((options) async {
        requests++;
        requestOptions = options;
        expect((options.data as Map)['middle_name'], isNull);
        return response.future;
      });
      final bloc = formBloc(client);
      addTearDown(client.dio.close);
      addTearDown(bloc.close);
      await showForm(
        tester,
        bloc,
        response: {...profileResponse, 'middleName': null},
      );
      await tester.ensureVisible(find.text('SAVE CHANGES'));
      await tester.tap(find.text('SAVE CHANGES'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(bloc.state, isA<EditProfileLoading>());
      final save = tester.widget<ElevatedButton>(
        find.descendant(
          of: find.byKey(const ValueKey('save_profile')),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(save.onPressed, isNull);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('EMAIL')))
            .enabled,
        isFalse,
      );
      response.complete(
        reply(requestOptions!, {...profileResponse, 'middleName': null}),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(bloc.state, isA<ProfileUpdated>());
      expect((bloc.state as ProfileUpdated).user.middleName, isNull);
      expect(requests, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('network failure shows actionable feedback', (tester) async {
    final client = contractClient(
      (options) async => throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      ),
    );
    final bloc = formBloc(client);
    addTearDown(client.dio.close);
    addTearDown(bloc.close);
    await showForm(tester, bloc);
    await tester.ensureVisible(find.text('SAVE CHANGES'));
    await tester.tap(find.text('SAVE CHANGES'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(
      find.text('No internet connection. Please try again.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('profile detail wraps a long address on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: ProfileDetailRow(
            label: 'ADDRESS',
            value: '123 J.P. Rizal Sta. Elena Marikina City',
          ),
        ),
      ),
    );
    expect(
      find.text('123 J.P. Rizal Sta. Elena Marikina City'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
