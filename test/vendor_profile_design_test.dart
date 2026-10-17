import 'profile_preview_capture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/router/mobile_route_access.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/features/auth/data/models/user_model.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:marikina_market_mobile/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:marikina_market_mobile/features/profile/presentation/pages/change_password_page.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/profile_content.dart';
import 'features/auth/data/login_mobile_contract_test.dart' show contractClient;
import 'features/profile/profile_form_test.dart' show formBloc;
import 'features/profile/profile_contract_test.dart' show profileResponse;
import 'vendor_profile_session_test.dart' show vendorAccount;

void main() {
  setUpAll(loadProfilePreviewFonts);
  for (final vendor in [false, true]) {
    for (final compact in [false, true]) {
      final label =
          '${vendor ? 'vendor' : 'enforcer'} ${compact ? '280px 2x' : '390px'}';
      testWidgets('$label profile matches shared design using cached data', (
        tester,
      ) async {
        tester.view.physicalSize = Size(compact ? 280 : 390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var requests = 0;
        final client = contractClient((_) async {
          requests++;
          throw StateError('Profile viewing must be offline.');
        });
        addTearDown(client.dio.close);
        final bloc = formBloc(client);
        addTearDown(bloc.close);
        final user = UserModel.fromJson(
          vendor ? vendorAccount : profileResponse,
        ).toEntity();
        final previewKey = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: previewKey,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: profilePreviewTheme,
              home: MediaQuery(
                data: MediaQueryData(
                  textScaler: TextScaler.linear(compact ? 2 : 1),
                ),
                child: BlocProvider<ProfileBloc>.value(
                  value: bloc,
                  child: Scaffold(body: ProfileContent(user: user)),
                ),
              ),
            ),
          ),
        );
        await captureProfilePreview(
          tester,
          previewKey,
          '${vendor ? 'vendor' : 'enforcer'}-profile-${compact ? '280-2x' : '390-1x'}',
        );
        expect(find.text('My Profile'), findsOneWidget);
        expect(
          tester.widget<Text>(find.text('My Profile')).style?.fontSize,
          24,
        );
        expect(
          find.text('Registered business'),
          vendor ? findsOneWidget : findsNothing,
        );
        if (vendor) {
          expect(find.byTooltip('My QR Code'), findsOneWidget);
          expect(find.text('Reyes Fresh Fish'), findsWidgets);
        }
        await tester.scrollUntilVisible(find.text('Log Out'), 240);
        expect(find.text('Edit Information'), findsOneWidget);
        expect(find.text('Change Password'), findsOneWidget);
        expect(requests, 0);
        expect(tester.takeException(), isNull);
      });

      testWidgets('$label password uses the shared password design', (
        tester,
      ) async {
        tester.view.physicalSize = Size(compact ? 280 : 390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final client = contractClient(
          (_) async => throw StateError('No submission expected.'),
        );
        addTearDown(client.dio.close);
        final bloc = formBloc(client);
        addTearDown(bloc.close);
        final user = UserModel.fromJson(
          vendor ? vendorAccount : profileResponse,
        ).toEntity();
        final previewKey = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: previewKey,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: profilePreviewTheme,
              home: MediaQuery(
                data: MediaQueryData(
                  textScaler: TextScaler.linear(compact ? 2 : 1),
                ),
                child: BlocProvider<ProfileBloc>.value(
                  value: bloc,
                  child: ChangePasswordPage(user: user),
                ),
              ),
            ),
          ),
        );
        await captureProfilePreview(
          tester,
          previewKey,
          '${vendor ? 'vendor' : 'enforcer'}-password-${compact ? '280-2x' : '390-1x'}',
        );
        expect(find.text('Update your password'), findsOneWidget);
        expect(find.text('Current Password'), findsOneWidget);
        expect(find.text('Confirm New Password'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Cancel'),
          240,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Save Changes'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
  test(
    'vendor may open shared account edit/password but not enforcer profile',
    () {
      final user = UserModel.fromJson(vendorAccount).toEntity();
      final state = Authenticated(user: user);
      expect(MobileRouteAccess.redirect(state, Routes.editProfile), isNull);
      expect(MobileRouteAccess.redirect(state, Routes.changePassword), isNull);
      expect(MobileRouteAccess.redirect(state, Routes.vendorQr), isNull);
      final enforcer = Authenticated(
        user: UserModel.fromJson(profileResponse).toEntity(),
      );
      expect(
        MobileRouteAccess.redirect(enforcer, Routes.vendorQr),
        Routes.dashboard,
      );
      expect(
        MobileRouteAccess.redirect(state, Routes.profile),
        Routes.vendorDashboard,
      );
    },
  );
}
