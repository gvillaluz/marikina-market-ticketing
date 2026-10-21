import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/connectivity/cubit/connectivity_cubit.dart';
import 'package:marikina_market_mobile/features/auth/data/models/user_model.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/profile_actions.dart';
import 'features/auth/login_mobile_flow_test.dart' show loginBloc;
import 'features/auth/login_test_network_info.dart';
import 'features/auth/data/login_mobile_contract_test.dart' show reply;
import 'vendor_profile_session_test.dart' show vendorAccount;
import 'profile_preview_capture.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  for (final dismissal in ['Cancel', 'Back']) {
    testWidgets('$dismissal dismisses logout confirmation without signing out', (
      tester,
    ) async {
      final previewKey = GlobalKey();
      await tester.runAsync(loadProfilePreviewFonts);
      await tester.pumpWidget(
        RepaintBoundary(
          key: previewKey,
          child: MaterialApp(
            theme: profilePreviewTheme,
            home: Scaffold(
              body: ProfileActions(
                user: UserModel.fromJson(vendorAccount).toEntity(),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();
      expect(find.text('Log out?'), findsOneWidget);
      await captureProfilePreview(tester, previewKey, 'logout-confirmation');
      if (dismissal == 'Cancel') {
        await tester.tap(find.text('Cancel'));
      } else {
        await tester.binding.handlePopRoute();
      }
      await tester.pumpAndSettle();
      expect(find.text('Log out?'), findsNothing);
      expect(find.text('Edit Information'), findsOneWidget);
      // No AuthBloc is installed: an accidental logout dispatch fails this test.
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('confirming logout invokes the existing logout request once', (
    tester,
  ) async {
    late ConnectivityCubit connectivity;
    late AuthBloc auth;
    var logoutRequests = 0;
    await tester.runAsync(() async {
      connectivity = ConnectivityCubit(LoginTestNetworkInfo());
      addTearDown(connectivity.close);
      auth = loginBloc(connectivity, (options) async {
        expect(options.path, '/Auth/logout');
        logoutRequests++;
        return reply(options, {'message': 'Logout confirmed.'});
      });
      addTearDown(auth.close);
      await auth.stream.firstWhere((state) => state is Unauthenticated);
      const storage = FlutterSecureStorage();
      await storage.write(key: 'device_token', value: 'synthetic-device-token');
      await storage.write(
        key: 'refresh_token',
        value: 'synthetic-refresh-token',
      );
    });
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: auth,
        child: MaterialApp(
          theme: profilePreviewTheme,
          home: Scaffold(
            body: ProfileActions(
              user: UserModel.fromJson(vendorAccount).toEntity(),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Log Out'));
    await tester.pumpAndSettle();
    expect(find.text('Log out?'), findsOneWidget);
    expect(logoutRequests, 0);
    await tester.tap(
      find.descendant(of: find.byType(Dialog), matching: find.text('Log Out')),
    );
    await tester.pumpAndSettle();
    for (var attempt = 0; attempt < 30 && logoutRequests == 0; attempt++) {
      await tester.pump(const Duration(milliseconds: 20));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 1)),
      );
    }
    await tester.pumpAndSettle();
    expect(logoutRequests, 1);
    expect(find.text('Log out?'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'logout confirmation remains usable at 280px and double text size',
    (tester) async {
      tester.view.physicalSize = const Size(280, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(loadProfilePreviewFonts);
      final previewKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: previewKey,
          child: MaterialApp(
            theme: profilePreviewTheme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: ProfileActions(
                    user: UserModel.fromJson(vendorAccount).toEntity(),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();
      expect(find.text('Log out?'), findsOneWidget);
      expect(
        MediaQuery.textScalerOf(
          tester.element(find.byType(AlertDialog)),
        ).scale(14),
        28,
      );
      await captureProfilePreview(
        tester,
        previewKey,
        'logout-confirmation-280-2x',
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
