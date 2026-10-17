import 'profile_preview_capture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:marikina_market_mobile/features/auth/data/models/user_model.dart';
import 'package:marikina_market_mobile/features/profile/presentation/pages/vendor_qr_page.dart';
import 'vendor_profile_session_test.dart' show vendorAccount;
import 'features/auth/data/login_mobile_contract_test.dart' show contractClient;
import 'features/profile/profile_form_test.dart' show formBloc;
import 'package:marikina_market_mobile/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/vendor_qr_actions.dart';

void main() {
  setUpAll(loadProfilePreviewFonts);
  for (final sharing in [true, false]) {
    testWidgets(
      'only the selected QR action loads and both actions are disabled: $sharing',
      (tester) async {
        final previewKey = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: previewKey,
            child: MaterialApp(
              theme: profilePreviewTheme,
              home: Scaffold(
                body: VendorQrActions(
                  busy: true,
                  sharing: sharing,
                  onShare: () => fail('Share must be disabled during export.'),
                  onSave: () =>
                      fail('Download must be disabled during export.'),
                ),
              ),
            ),
          ),
        );
        await captureProfilePreview(
          tester,
          previewKey,
          sharing ? 'qr-sharing' : 'qr-downloading',
        );
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(
          find.text(sharing ? 'Sharing…' : 'Preparing download…'),
          findsOneWidget,
        );
        expect(
          find.text(sharing ? 'Download QR Code' : 'Share QR Code'),
          findsOneWidget,
        );
        for (final button in tester.widgetList<OutlinedButton>(
          find.byType(OutlinedButton),
        )) {
          expect(button.onPressed, isNull);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final compact in [false, true]) {
    testWidgets(
      'QR uses the cached scan token at ${compact ? '280px 2x' : '390px'}',
      (tester) async {
        tester.view.physicalSize = Size(compact ? 280 : 390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final client = contractClient(
          (_) async => throw StateError('QR viewing must use the cache.'),
        );
        addTearDown(client.dio.close);
        final bloc = formBloc(client);
        addTearDown(bloc.close);
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
                  child: VendorQrPage(
                    user: UserModel.fromJson(vendorAccount).toEntity(),
                  ),
                ),
              ),
            ),
          ),
        );
        await captureProfilePreview(
          tester,
          previewKey,
          'vendor-qr-${compact ? '280-2x' : '390-1x'}',
        );
        expect(find.text('My QR Code'), findsOneWidget);
        expect(find.byType(QrImageView), findsOneWidget);
        expect(find.text('MM-70'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('Download QR Code'), 240);
        expect(find.text('Share QR Code'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
