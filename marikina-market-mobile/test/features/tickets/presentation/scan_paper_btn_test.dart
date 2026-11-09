import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/app_primary_btn.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/scan_paper_btn.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/inspection_evidence_grid.dart';

const scanner = MethodChannel('cunning_document_scanner');
const picker = MethodChannel('plugins.flutter.io/image_picker');
const scanLabel = 'Scan paper ticket';
const fallbackLabel = 'Take a normal photo instead';
const unavailableMessage = 'The scanner is unavailable on this phone.';

void mockScanner(Future<Object?> Function(MethodCall call)? handler) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(scanner, handler);
}

void mockPicker(Future<Object?> Function(MethodCall call)? handler) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(picker, handler);
}

Future<void> flush(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 20)),
  );
  await tester.pump();
}

XFile photoFile(WidgetTester tester) {
  final path = File('assets/logo/org_logo.png').absolute.path;
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });
  return XFile(path);
}

Future<void> showButton(
  WidgetTester tester, {
  List<XFile> photos = const [],
  ValueChanged<XFile>? onAdded,
  ValueChanged<int>? onRemoved,
}) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ScanPaperBtn(
            photos: photos,
            buttonLabel: scanLabel,
            onPhotoAdded: onAdded ?? (_) {},
            onPhotoRemoved: onRemoved ?? (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.runAsync(() async {
    for (final photo in photos) {
      await precacheImage(
        FileImage(File(photo.path)),
        tester.element(find.byType(Scaffold)),
      );
    }
  });
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() {
    mockScanner(null);
    mockPicker(null);
  });

  testWidgets('opens the scanner for one camera page without filters', (
    tester,
  ) async {
    MethodCall? seen;
    mockScanner((call) async {
      seen = call;
      return null;
    });
    await showButton(tester);
    await tester.tap(find.text(scanLabel));
    await flush(tester);
    expect(seen!.method, 'getPictures');
    final arguments = seen!.arguments as Map<Object?, Object?>;
    expect(arguments['noOfPages'], 1);
    expect(arguments['scannerSource'], 'camera');
    expect(arguments['androidScannerMode'], 'base');
    expect(arguments['asPdf'], false);
  });

  testWidgets('the scanned page is handed over once', (tester) async {
    final page = photoFile(tester);
    final added = <XFile>[];
    mockScanner((_) async => [page.path]);
    await showButton(tester, onAdded: added.add);
    await tester.tap(find.text(scanLabel));
    await flush(tester);
    expect(added.map((file) => file.path), [page.path]);
    expect(find.text(scanLabel), findsOneWidget);
    expect(find.text(unavailableMessage), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a second tap while the scanner is open does nothing', (
    tester,
  ) async {
    final pending = Completer<Object?>();
    var calls = 0;
    mockScanner((_) {
      calls++;
      return pending.future;
    });
    await showButton(tester);
    await tester.tap(find.text(scanLabel));
    await flush(tester);
    expect(find.text('Opening scanner'), findsOneWidget);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
    await tester.tap(find.text('Opening scanner'));
    expect(calls, 1);
    pending.complete(null);
    await flush(tester);
    expect(find.text(scanLabel), findsOneWidget);
  });

  testWidgets('two scan actions in a row open only one scanner', (
    tester,
  ) async {
    final pending = Completer<Object?>();
    var calls = 0;
    mockScanner((_) {
      calls++;
      return pending.future;
    });
    await showButton(tester);
    final action = tester
        .widget<AppPrimaryButton>(find.byType(AppPrimaryButton))
        .onPressed!;
    action();
    action();
    await flush(tester);
    expect(calls, 1);
    pending.complete(null);
    await flush(tester);
  });

  testWidgets('cancelling changes nothing and shows no message', (
    tester,
  ) async {
    var added = 0;
    mockScanner((_) async => null);
    await showButton(tester, onAdded: (_) => added++);
    await tester.tap(find.text(scanLabel));
    await flush(tester);
    expect(added, 0);
    expect(find.text(unavailableMessage), findsNothing);
    expect(find.text(fallbackLabel), findsNothing);
    expect(find.text(scanLabel), findsOneWidget);
  });

  testWidgets('cancelling after a failure keeps the message and fallback', (
    tester,
  ) async {
    var calls = 0;
    mockScanner((_) async {
      if (++calls == 1) throw PlatformException(code: 'scan_failed');
      return null;
    });
    await showButton(tester);
    await tester.tap(find.text(scanLabel));
    await flush(tester);
    await tester.tap(find.text(scanLabel));
    await flush(tester);
    expect(calls, 2);
    expect(find.text(unavailableMessage), findsOneWidget);
    expect(find.text(fallbackLabel), findsOneWidget);
  });

  testWidgets('the normal-photo button is hidden until the scanner fails', (
    tester,
  ) async {
    await showButton(tester);
    expect(find.text(fallbackLabel), findsNothing);
    expect(find.text(unavailableMessage), findsNothing);
  });

  testWidgets('a scanner failure offers a normal photo that is then kept', (
    tester,
  ) async {
    final photo = photoFile(tester);
    final added = <XFile>[];
    mockScanner((_) async => throw PlatformException(code: 'scan_failed'));
    MethodCall? pickerCall;
    mockPicker((call) async {
      pickerCall = call;
      return photo.path;
    });
    await showButton(tester, onAdded: added.add);
    await tester.tap(find.text(scanLabel));
    await flush(tester);
    expect(find.text(unavailableMessage), findsOneWidget);
    expect(find.text(fallbackLabel), findsOneWidget);
    expect(added, isEmpty);
    await tester.ensureVisible(find.text(fallbackLabel));
    await tester.tap(find.text(fallbackLabel));
    await flush(tester);
    final arguments = pickerCall!.arguments as Map<Object?, Object?>;
    expect(arguments['source'], 0); // ImageSource.camera
    expect(added.map((file) => file.path), [photo.path]);
  });

  testWidgets('a missing scanner plugin is treated as unavailable', (
    tester,
  ) async {
    await showButton(tester);
    await tester.tap(find.text(scanLabel));
    await flush(tester);
    expect(find.text(unavailableMessage), findsOneWidget);
    expect(find.text(fallbackLabel), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a later successful scan clears the unavailable message', (
    tester,
  ) async {
    final page = photoFile(tester);
    var calls = 0;
    mockScanner((_) async {
      if (++calls == 1) throw PlatformException(code: 'scan_failed');
      return [page.path];
    });
    await showButton(tester);
    await tester.tap(find.text(scanLabel));
    await flush(tester);
    expect(find.text(unavailableMessage), findsOneWidget);
    await tester.tap(find.text(scanLabel));
    await flush(tester);
    expect(find.text(unavailableMessage), findsNothing);
    expect(find.text(fallbackLabel), findsNothing);
  });

  testWidgets('the kept page shows once and can be removed', (tester) async {
    final page = photoFile(tester);
    int? removed;
    await showButton(tester, photos: [page], onRemoved: (i) => removed = i);
    expect(find.byType(InspectionEvidenceGrid), findsOneWidget);
    final target = find.byTooltip('Remove photo 1');
    await tester.ensureVisible(target);
    await tester.tapAt(tester.getTopLeft(target) + const Offset(2, 2));
    expect(removed, 0);
  });

  testWidgets('the kept page shows once even after a scanner failure', (
    tester,
  ) async {
    final page = photoFile(tester);
    mockScanner((_) async => throw PlatformException(code: 'scan_failed'));
    await showButton(tester, photos: [page]);
    await tester.tap(find.text(scanLabel));
    await flush(tester);
    expect(find.text(unavailableMessage), findsOneWidget);
    expect(find.byType(InspectionEvidenceGrid), findsOneWidget);
  });
}
