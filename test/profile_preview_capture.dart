import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

const profilePreviewsEnabled = bool.fromEnvironment('PROFILE_UI_PREVIEWS');
const profilePreviewDirectory = String.fromEnvironment(
  'PROFILE_UI_PREVIEW_DIRECTORY',
  defaultValue: 'evidence/vendor-profile-cached-ui',
);

Future<void> loadProfilePreviewFonts() async {
  if (!profilePreviewsEnabled) return;
  for (final entry in {
    'Roboto':
        'C:/develop/flutter/engine/src/flutter/txt/third_party/fonts/Roboto-Regular.ttf',
    'MaterialIcons':
        'C:/develop/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  }.entries) {
    final loader = FontLoader(entry.key)
      ..addFont(
        File(
          entry.value,
        ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
      );
    await loader.load();
  }
}

Future<void> captureProfilePreview(
  WidgetTester tester,
  GlobalKey key,
  String name,
) async {
  if (!profilePreviewsEnabled) return;
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    try {
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        '$profilePreviewDirectory/$name.png',
      ).writeAsBytes(png!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

ThemeData get profilePreviewTheme {
  final theme = AppTheme.light;
  if (!profilePreviewsEnabled) return theme;
  final text = AppTheme.buttonTextStyle.copyWith(fontFamily: 'Roboto');
  return theme.copyWith(
    textTheme: theme.textTheme.apply(fontFamily: 'Roboto'),
    primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: 'Roboto'),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: theme.elevatedButtonTheme.style?.copyWith(
        textStyle: WidgetStatePropertyAll(text),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: theme.outlinedButtonTheme.style?.copyWith(
        textStyle: WidgetStatePropertyAll(text),
      ),
    ),
  );
}
