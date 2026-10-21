import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/qr_scanner_overlay.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/qr_scanner_camera_controls.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/qr_scanner_camera_error.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/qr_scanner_status.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/scanner_corner_pointer.dart';

BarcodeCapture codeAt(
  List<Offset> corners, {
  Size size = const Size(400, 800),
}) => BarcodeCapture(
  size: size,
  barcodes: [Barcode(format: BarcodeFormat.qrCode, corners: corners)],
);

void main() {
  test('portrait projection fits a code on the left of the preview', () {
    final capture = codeAt(const [
      Offset(20, 200),
      Offset(100, 200),
      Offset(100, 280),
      Offset(20, 280),
    ]);
    expect(
      QrScannerOverlay.boundsFor(
        capture,
        const Size(200, 400),
        DeviceOrientation.portraitUp,
      ),
      const Rect.fromLTRB(2, 92, 58, 148),
    );
  });
  test('cover projection subtracts the cropped preview offset', () {
    final capture = codeAt(const [
      Offset(20, 300),
      Offset(100, 300),
      Offset(100, 380),
      Offset(20, 380),
    ]);
    expect(
      QrScannerOverlay.boundsFor(
        capture,
        const Size(400, 400),
        DeviceOrientation.portraitUp,
      ),
      const Rect.fromLTRB(12, 92, 108, 188),
    );
  });
  test('landscape projection uses the scanner adjusted preview dimensions', () {
    final capture = codeAt(const [
      Offset(200, 80),
      Offset(280, 80),
      Offset(280, 160),
      Offset(200, 160),
    ]);
    expect(
      QrScannerOverlay.boundsFor(
        capture,
        const Size(400, 200),
        DeviceOrientation.landscapeLeft,
      ),
      const Rect.fromLTRB(92, 32, 148, 88),
    );
  });
  test('missing or malformed coordinates keep the guide fallback', () {
    expect(
      QrScannerOverlay.boundsFor(
        codeAt([]),
        const Size(200, 400),
        DeviceOrientation.portraitUp,
      ),
      isNull,
    );
    expect(
      QrScannerOverlay.boundsFor(
        const BarcodeCapture(),
        const Size(200, 400),
        DeviceOrientation.portraitUp,
      ),
      isNull,
    );
    expect(
      QrScannerOverlay.boundsFor(
        codeAt(const [
          Offset(double.nan, 1),
          Offset(2, 3),
          Offset(4, 5),
          Offset(6, 7),
        ]),
        const Size(200, 400),
        DeviceOrientation.portraitUp,
      ),
      isNull,
    );
  });
  testWidgets(
    'border moves from its guide to detected bounds and honors reduced motion',
    (tester) async {
      final capture = codeAt(const [
        Offset(20, 200),
        Offset(100, 200),
        Offset(100, 280),
        Offset(20, 280),
      ]);
      Future<void> show(BarcodeCapture? scan, bool reduced) =>
          tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(disableAnimations: reduced),
                child: Scaffold(
                  body: SizedBox(
                    width: 200,
                    height: 400,
                    child: QrScannerOverlay(
                      capture: scan,
                      orientation: DeviceOrientation.portraitUp,
                    ),
                  ),
                ),
              ),
            ),
          );
      await show(null, false);
      final border = find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint && widget.painter is ScannerCornersPainter,
      );
      expect(tester.getRect(border).center, const Offset(100, 200));
      await show(capture, false);
      await tester.pump(const Duration(milliseconds: 80));
      expect(tester.getRect(border).center.dx, lessThan(100));
      await tester.pumpAndSettle();
      expect(tester.getRect(border), const Rect.fromLTRB(2, 92, 58, 148));
      await show(null, true);
      await tester.pump();
      expect(tester.getRect(border).center, const Offset(100, 200));
      expect(tester.binding.hasScheduledFrame, isFalse);
    },
  );
  testWidgets(
    'flash control stays visible, reflects its state, and disables while busy',
    (tester) async {
      const channel = MethodChannel(
        'dev.steenbakker.mobile_scanner/scanner/method',
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (_) async => null,
      );
      final controller = MobileScannerController(autoStart: false);
      addTearDown(() async {
        await controller.dispose();
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        );
      });
      controller.value = controller.value.copyWith(
        isInitialized: true,
        isRunning: true,
        availableCameras: 2,
        torchState: TorchState.off,
      );
      var toggles = 0;
      Future<void> show(bool busy) => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                QrScannerCameraControls(
                  controller: controller,
                  isBusy: busy,
                  onToggleTorch: () => toggles++,
                  onSwitchCamera: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await show(false);
      await tester.tap(find.byTooltip('Turn flash on'));
      expect(toggles, 1);
      controller.value = controller.value.copyWith(torchState: TorchState.on);
      await tester.pump();
      expect(find.byTooltip('Turn flash off'), findsOneWidget);
      expect(find.byIcon(Icons.flash_on), findsOneWidget);
      await show(true);
      expect(
        tester
            .widget<IconButton>(
              find.ancestor(
                of: find.byIcon(Icons.flash_on),
                matching: find.byType(IconButton),
              ),
            )
            .onPressed,
        isNull,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'scanner feedback and permission actions fit narrow large-text screens',
    (tester) async {
      tester.view.physicalSize = const Size(280, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(280, 640),
              textScaler: TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: Scaffold(
              body: Column(
                children: [
                  const Expanded(
                    child: QrScannerCameraError(
                      errorCode: MobileScannerErrorCode.permissionDenied,
                      onRetry: null,
                    ),
                  ),
                  QrScannerStatus(
                    message:
                        'Unable to find this vendor. Please check the code and try again.',
                    onRetry: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.text('Open app settings'), findsOneWidget);
      expect(find.text('Scan again'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
