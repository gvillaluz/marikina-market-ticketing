import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/add_photo_evidence_btn.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/evidence_gallery_screen.dart';

const picker = MethodChannel('plugins.flutter.io/image_picker');
const formControlsPreviews = bool.fromEnvironment('SLICE3B_PREVIEWS');

ThemeData get formControlsPreviewTheme => formControlsPreviews
    ? AppTheme.light.copyWith(
        textTheme: AppTheme.light.textTheme.apply(fontFamily: 'Roboto'),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: AppTheme.light.elevatedButtonTheme.style?.copyWith(
            textStyle: WidgetStatePropertyAll(
              AppTheme.buttonTextStyle.copyWith(fontFamily: 'Roboto'),
            ),
          ),
        ),
      )
    : AppTheme.light;

Future<void> loadFormControlPreviewFonts() async {
  if (!formControlsPreviews) return;
  final root = Platform.environment['FLUTTER_ROOT']!;
  for (final entry in {
    'Roboto': 'roboto-regular.ttf',
    'MaterialIcons': 'MaterialIcons-Regular.otf',
  }.entries) {
    await (FontLoader(entry.key)..addFont(
          File(
            '$root/bin/cache/artifacts/material_fonts/${entry.value}',
          ).readAsBytes().then(ByteData.sublistView),
        ))
        .load();
  }
}

Future<void> captureFormControls(WidgetTester tester, String name) async {
  if (!formControlsPreviews) return;
  for (var frame = 0; frame < 20; frame++) {
    if (!tester
        .widgetList<RawImage>(find.byType(RawImage))
        .any((image) => image.image == null))
      break;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }
  await tester.pump();
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('form-controls-preview')),
    );
    final image = await boundary.toImage();
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        '../evidence/enforcer-form-controls-slice-3b/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

Future<void> flushCamera(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 20)),
  );
  await tester.pump();
}

Future<XFile> photoFixture(WidgetTester tester, String name) {
  // Two bundled, non-sensitive images provide distinct gallery/hero identities.
  final path = File(
    name.contains('second')
        ? 'assets/splash/logo.png'
        : 'assets/logo/org_logo.png',
  ).absolute.path;
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });
  return Future.value(XFile(path));
}

Future<void> showControls(
  WidgetTester tester, {
  double width = 280,
  List<XFile> photos = const [],
  ValueChanged<XFile>? onAdded,
  ValueChanged<int>? onRemoved,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: formControlsPreviewTheme,
      builder: (_, child) => RepaintBoundary(
        key: const ValueKey('form-controls-preview'),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: AddPhotoEvidenceBtn(
            photos: photos,
            onPhotoAdded: onAdded ?? (_) {},
            onPhotoRemoved: onRemoved ?? (_) {},
            isInvalid: false,
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
  setUpAll(loadFormControlPreviewFonts);
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(picker, null);
  });

  for (final width in [280.0, 400.0]) {
    testWidgets('photo action has only button height at ${width}px', (
      tester,
    ) async {
      await showControls(tester, width: width);
      // The existing primary-button height is 52px; no extra 40px frame padding.
      expect(tester.getSize(find.byType(AddPhotoEvidenceBtn)).height, 52);
      expect(tester.getSize(find.byType(ElevatedButton)).width, width - 40);
      expect(find.text('Take a photo'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await captureFormControls(tester, 'photo-action-${width.toInt()}');
    });
  }

  testWidgets(
    'camera success adds once and blocks repeated capture while busy',
    (tester) async {
      final photo = await photoFixture(tester, 'captured');
      final pending = Completer<String?>();
      final added = <XFile>[];
      var calls = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(picker, (call) async {
            expect(call.method, 'pickImage');
            final arguments = call.arguments as Map<Object?, Object?>;
            expect(arguments['source'], 0); // ImageSource.camera
            expect(arguments['cameraDevice'], 0); // CameraDevice.rear
            calls++;
            return pending.future;
          });
      await showControls(tester, onAdded: added.add);
      await tester.tap(find.text('Take a photo'));
      await flushCamera(tester);
      expect(find.text('Opening camera'), findsOneWidget);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
      await tester.tap(find.text('Opening camera'));
      expect(calls, 1);
      pending.complete(photo.path);
      await flushCamera(tester);
      expect(added.map((file) => file.path), [photo.path]);
      expect(find.text('Take a photo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('camera cancellation leaves the photo list unchanged', (
    tester,
  ) async {
    var added = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(picker, (_) async => null);
    await showControls(tester, onAdded: (_) => added++);
    await tester.tap(find.text('Take a photo'));
    await flushCamera(tester);
    expect(added, 0);
    expect(find.text('Take a photo'), findsOneWidget);
    expect(find.textContaining('Unable to'), findsNothing);
  });

  testWidgets('camera failure is readable and the next capture can succeed', (
    tester,
  ) async {
    final photo = await photoFixture(tester, 'retry');
    var calls = 0;
    final added = <XFile>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(picker, (_) async {
          if (++calls == 1) throw PlatformException(code: 'camera_unavailable');
          return photo.path;
        });
    await showControls(tester, onAdded: added.add);
    await tester.tap(find.text('Take a photo'));
    await flushCamera(tester);
    expect(
      find.text('Unable to open the camera. Please try again.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Take a photo'));
    await flushCamera(tester);
    expect(added.map((file) => file.path), [photo.path]);
    expect(
      find.text('Unable to open the camera. Please try again.'),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing camera plugin shows the existing unavailable message', (
    tester,
  ) async {
    await showControls(tester);
    await tester.tap(find.text('Take a photo'));
    await flushCamera(tester);
    expect(
      find.text('Camera capture is unavailable on this device.'),
      findsOneWidget,
    );
    expect(find.text('Take a photo'), findsOneWidget);
  });

  for (final width in [280.0, 400.0]) {
    testWidgets('20px remove icon keeps a 48px target at ${width}px', (
      tester,
    ) async {
      final first = await photoFixture(tester, 'first');
      final second = await photoFixture(tester, 'second');
      int? removed;
      await showControls(
        tester,
        width: width,
        photos: [first, second],
        onRemoved: (index) => removed = index,
      );
      final target = find.byTooltip('Remove photo 2');
      await tester.ensureVisible(target);
      await tester.pump();
      final icon = find.descendant(
        of: target,
        matching: find.byIcon(Icons.close),
      );
      expect(tester.getSize(icon), const Size(20, 20));
      expect(tester.getSize(target).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
      await captureFormControls(tester, 'photo-grid-${width.toInt()}');
      await tester.tapAt(tester.getTopLeft(target) + const Offset(2, 2));
      expect(removed, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('camera evidence opens the existing gallery at 400px', (
    tester,
  ) async {
    final first = await photoFixture(tester, 'gallery-first');
    final second = await photoFixture(tester, 'gallery-second');
    await showControls(tester, width: 400, photos: [first, second]);
    final image = find.byType(Image).first;
    await tester.ensureVisible(image);
    await tester.tap(image);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(EvidenceGalleryScreen), findsOneWidget);
    expect(find.text('Image 1 of 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // Permission state is cached by the existing utility; keep this scenario last.
  testWidgets('camera denial retains the existing permission guidance', (
    tester,
  ) async {
    var added = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(picker, (_) async {
          throw PlatformException(code: 'camera_access_denied');
        });
    await showControls(tester, onAdded: (_) => added++);
    await tester.tap(find.text('Take a photo'));
    await flushCamera(tester);
    expect(
      find.text(
        'Camera permission was denied. Enable it in your device settings to attach a photo.',
      ),
      findsOneWidget,
    );
    expect(added, 0);
    expect(find.text('Take a photo'), findsOneWidget);
  });
}
