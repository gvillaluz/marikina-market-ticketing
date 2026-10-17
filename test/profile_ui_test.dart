import 'dart:async';
import 'profile_preview_capture.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/auth/data/models/user_model.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/profile_header_card.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/change_password_card.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/save_btn.dart';
import 'package:marikina_market_mobile/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:marikina_market_mobile/features/profile/presentation/bloc/profile_state.dart';
import 'package:marikina_market_mobile/features/profile/presentation/bloc/profile_event.dart';
import 'features/profile/profile_form_test.dart' show formBloc;
import 'features/profile/profile_contract_test.dart' show profileResponse;
import 'features/auth/data/login_mobile_contract_test.dart' show contractClient;

void main() {
  testWidgets('profile identity is centered within its card', (tester) async {
    final previewKey = GlobalKey();
    await tester.runAsync(loadProfilePreviewFonts);
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final user = UserModel.fromJson(profileResponse).toEntity();
    await tester.pumpWidget(
      RepaintBoundary(
        key: previewKey,
        child: MaterialApp(
          theme: profilePreviewTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              padding: AppTheme.profilePagePadding,
              child: ProfileHeaderCard(
                user: user,
                onChangePhoto: (_) {},
                onRemovePhoto: () {},
              ),
            ),
          ),
        ),
      ),
    );
    final centerX = tester.getCenter(find.byType(ProfileHeaderCard)).dx;
    final name = tester.widget<Text>(
      find.text('${user.lastName}, ${user.firstName}'),
    );
    expect(name.textAlign, TextAlign.center);
    expect(find.text('Marikina Public Market Office'), findsNothing);
    expect(
      tester.getCenter(find.byIcon(Icons.person_outline)).dx,
      closeTo(centerX, 1),
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Profile photo actions'));
    await tester.pumpAndSettle();
    expect(find.text('Add Photo'), findsOneWidget);
    await captureProfilePreview(tester, previewKey, 'profile-photo-options');
  });
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  testWidgets(
    'profile header wraps a long name and role at 280px with large text',
    (tester) async {
      tester.view.physicalSize = const Size(280, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final user = UserModel.fromJson({
        ...profileResponse,
        'firstName': 'Maria Isabel',
        'lastName': 'Dela Cruz Santos',
      }).toEntity();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ProfileHeaderCard(
                  user: user,
                  onChangePhoto: (_) {},
                  onRemovePhoto: () {},
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Dela Cruz Santos, Maria Isabel'), findsOneWidget);
    },
  );
  testWidgets(
    'profile passwords are obscured and cannot be edited while changing',
    (tester) async {
      final requested = Completer<RequestOptions>();
      final pending = Completer<Response<Object?>>();
      final client = contractClient((options) {
        requested.complete(options);
        return pending.future;
      });
      addTearDown(client.dio.close);
      final bloc = formBloc(client);
      addTearDown(bloc.close);
      final current = TextEditingController(text: 'OldPass123');
      final next = TextEditingController(text: ' NewPass123 ');
      final confirm = TextEditingController(text: ' NewPass123 ');
      addTearDown(current.dispose);
      addTearDown(next.dispose);
      addTearDown(confirm.dispose);
      await tester.pumpWidget(
        BlocProvider<ProfileBloc>.value(
          value: bloc,
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: SingleChildScrollView(
                child: ChangePasswordCard(
                  currentPasswordController: current,
                  newPasswordController: next,
                  confirmNewPasswordController: confirm,
                  submit: () {},
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        tester
            .widgetList<TextField>(find.byType(TextField))
            .every((field) => field.obscureText),
        isTrue,
      );
      bloc.add(
        UpdatePasswordSubmitted(
          userId: 7,
          currentPassword: current.text,
          newPassword: next.text,
          confirmNewPassword: confirm.text,
        ),
      );
      final options = await tester.runAsync(() => requested.future);
      await tester.pump();
      expect(
        tester
            .widgetList<TextField>(find.byType(TextField))
            .every((field) => field.enabled == false),
        isTrue,
      );
      expect(next.text, ' NewPass123 ');
      final failed = bloc.stream.firstWhere(
        (state) => state is ChangePasswordNetworkError,
      );
      await tester.runAsync(() async {
        pending.completeError(
          DioException(
            requestOptions: options!,
            type: DioExceptionType.connectionError,
          ),
        );
        await failed;
      });
      await tester.pump();
      expect(
        tester
            .widgetList<TextField>(find.byType(TextField))
            .every((field) => field.enabled == true),
        isTrue,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('save action retains label with reduced-motion loading', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(body: SaveBtn(onPressed: () {}, isLoading: true)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('SAVE CHANGES'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
