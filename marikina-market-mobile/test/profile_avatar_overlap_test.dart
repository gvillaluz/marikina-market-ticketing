import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marikina_market_mobile/features/auth/data/models/user_model.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/profile_header_card.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/profile_portrait.dart';
import 'features/profile/profile_contract_test.dart' show profileResponse;
import 'vendor_profile_session_test.dart' show vendorAccount;
import 'profile_preview_capture.dart';

const pickerChannel = MethodChannel('plugins.flutter.io/image_picker');

Finder get cameraButton => find.descendant(
  of: find.byType(ProfileAvatar),
  matching: find.byType(IconButton),
);

Future<void> showAvatar(
  WidgetTester tester, {
  bool updating = false,
  String? url,
  ValueChanged<XFile>? onChange,
  VoidCallback? onRemove,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: profilePreviewTheme,
      home: Scaffold(
        body: Center(
          child: ProfileAvatar(
            profileUrl: url,
            isUpdating: updating,
            onChangePhoto: onChange ?? (_) {},
            onRemovePhoto: onRemove ?? () {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> choosePhoto(WidgetTester tester) async {
  await tester.tap(cameraButton);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Add Photo'));
  await tester.pump();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 20)),
  );
  await tester.pump();
}

Future<void> flushPicker(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 20)),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    if (!profilePreviewsEnabled) return;
    final sdkRoot = Platform.environment['FLUTTER_ROOT']!;
    for (final font in {
      'Roboto': 'Roboto-Regular.ttf',
      'MaterialIcons': 'MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(font.key)..addFont(
            File(
              '$sdkRoot/bin/cache/artifacts/material_fonts/${font.value}',
            ).readAsBytes().then(ByteData.sublistView),
          ))
          .load();
    }
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pickerChannel, null);
  });

  for (final vendor in [false, true]) {
    for (final compact in [false, true]) {
      final label =
          '${vendor ? 'vendor' : 'enforcer'}-${compact ? '280-2x' : '390-1x'}';
      testWidgets(
        '$label camera overlaps portrait and outer target opens options',
        (tester) async {
          tester.view.physicalSize = Size(compact ? 280 : 390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
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
                  child: Scaffold(
                    body: SingleChildScrollView(
                      child: ProfileHeaderCard(
                        user: user,
                        onChangePhoto: (_) {},
                        onRemovePhoto: () {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final portrait = tester.getRect(find.byType(ProfilePortrait));
          final target = tester.getRect(cameraButton);
          final face = tester.getRect(
            find
                .descendant(of: cameraButton, matching: find.byType(Material))
                .last,
          );
          expect(portrait.size, const Size(92, 92));
          expect(
            portrait.center.dx,
            closeTo(tester.getCenter(find.byType(ProfileHeaderCard)).dx, .01),
          );
          expect(face.right - portrait.right, closeTo(10, .01));
          expect(face.bottom - portrait.bottom, closeTo(10, .01));
          expect(face.left, lessThan(portrait.right));
          expect(face.top, lessThan(portrait.bottom));
          expect(target.width, greaterThanOrEqualTo(48));
          expect(target.height, greaterThanOrEqualTo(48));
          expect(
            tester
                .getRect(find.byType(ProfileAvatar))
                .contains(target.bottomRight - const Offset(1, 1)),
            isTrue,
          );
          expect(
            target.bottom,
            lessThan(
              tester
                  .getTopLeft(find.text('${user.lastName}, ${user.firstName}'))
                  .dy,
            ),
          );
          expect(tester.takeException(), isNull);
          await captureProfilePreview(tester, previewKey, label);
          final outerPoint = Offset(target.right - 2, target.center.dy);
          expect(outerPoint.dx, greaterThan(portrait.right));
          await tester.tapAt(outerPoint);
          await tester.pumpAndSettle();
          expect(find.text('Add Photo'), findsOneWidget);
          expect(find.text('Remove Photo'), findsNothing);
          await tester.tap(find.text('Cancel'));
          await tester.pumpAndSettle();
          expect(find.text('Add Photo'), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'updating photo disables the outer target and retains accessible progress',
    (tester) async {
      await showAvatar(tester, updating: true);
      expect(find.byTooltip('Updating profile photo'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.widget<IconButton>(cameraButton).onPressed, isNull);
      final target = tester.getRect(cameraButton);
      await tester.tapAt(Offset(target.right - 2, target.center.dy));
      await tester.pump();
      expect(find.text('Add Photo'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'gallery success calls change once and duplicate taps remain disabled',
    (tester) async {
      final completion = Completer<String?>();
      var requests = 0;
      final changes = <XFile>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pickerChannel, (call) async {
            expect(call.method, 'pickImage');
            expect((call.arguments as Map<Object?, Object?>)['source'], 1);
            requests++;
            return completion.future;
          });
      await showAvatar(tester, onChange: changes.add);
      await choosePhoto(tester);
      expect(requests, 1);
      expect(tester.widget<IconButton>(cameraButton).onPressed, isNull);
      await tester.tapAt(tester.getCenter(cameraButton));
      await tester.pump();
      expect(requests, 1);
      final path = File('assets/logo/org_logo.png').absolute.path;
      await tester.runAsync(() async {
        completion.complete(path);
      });
      await flushPicker(tester);
      expect(changes.map((file) => file.path), [path]);
      expect(tester.widget<IconButton>(cameraButton).onPressed, isNotNull);
    },
  );

  testWidgets(
    'gallery cancellation leaves photo unchanged and restores actions',
    (tester) async {
      var changes = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pickerChannel, (_) async => null);
      await showAvatar(tester, onChange: (_) => changes++);
      await choosePhoto(tester);
      await flushPicker(tester);
      expect(changes, 0);
      expect(tester.widget<IconButton>(cameraButton).onPressed, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'gallery platform error shows retry message and restores actions',
    (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            pickerChannel,
            (_) async => throw PlatformException(code: 'picker_error'),
          );
      await showAvatar(tester);
      await choosePhoto(tester);
      await flushPicker(tester);
      expect(
        find.text('Unable to open your photos. Please try again.'),
        findsOneWidget,
      );
      expect(tester.widget<IconButton>(cameraButton).onPressed, isNotNull);
    },
  );

  testWidgets(
    'existing photo exposes change and removal without opening gallery',
    (tester) async {
      var removals = 0;
      var picks = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pickerChannel, (_) async {
            picks++;
            return null;
          });
      await showAvatar(
        tester,
        url: 'https://example.invalid/synthetic-avatar.png',
        onRemove: () => removals++,
      );
      await tester.tap(cameraButton);
      await tester.pumpAndSettle();
      expect(find.text('Change Photo'), findsOneWidget);
      expect(find.text('Remove Photo'), findsOneWidget);
      await tester.tap(find.text('Remove Photo'));
      await tester.pumpAndSettle();
      expect(removals, 1);
      expect(picks, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
