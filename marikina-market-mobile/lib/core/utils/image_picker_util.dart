import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerUtil {
  ImagePickerUtil._();

  static const MethodChannel _settingsChannel = MethodChannel(
    'marikina_market_mobile/app_settings',
  );
  static final Set<ImageSource> _deniedSources = {};

  static Future<void> openPermissionSettings(
    BuildContext context, {
    required String permission,
  }) async {
    try {
      final openedSettings =
          await _settingsChannel.invokeMethod<bool>('openAppSettings') ?? false;
      if (!context.mounted || openedSettings) return;

      _showSettingsError(context, permission);
    } on PlatformException {
      if (!context.mounted) return;
      _showSettingsError(context, permission);
    } on MissingPluginException {
      if (!context.mounted) return;
      _showSettingsError(context, permission);
    }
  }

  static void _showSettingsError(BuildContext context, String permission) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Unable to open app settings. Please open them manually to enable $permission access.',
          ),
        ),
      );
  }

  static Future<XFile?> pickImage({
    required BuildContext context,
    required ImageSource source,
    int imageQuality = 100,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    if (_deniedSources.contains(source)) {
      await openPermissionSettings(
        context,
        permission: source == ImageSource.camera
            ? 'camera'
            : 'photo and storage',
      );
      return null;
    }

    try {
      final photo = await ImagePicker().pickImage(
        source: source,
        imageQuality: imageQuality,
        preferredCameraDevice: preferredCameraDevice,
      );
      _deniedSources.remove(source);
      return photo;
    } on PlatformException catch (error) {
      final code = error.code.toLowerCase();
      final message = (error.message ?? '').toLowerCase();
      final denied =
          code.contains('denied') ||
          code.contains('restricted') ||
          message.contains('permission denied');
      final isCamera = code.contains('camera') || source == ImageSource.camera;
      final isMedia =
          code.contains('photo') ||
          code.contains('gallery') ||
          code.contains('storage') ||
          code.contains('media') ||
          source == ImageSource.gallery;

      if (!denied || (!isCamera && !isMedia)) rethrow;
      _deniedSources.add(source);
      if (!context.mounted) return null;

      final permission = isCamera ? 'Camera' : 'Photo and storage';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '$permission permission was denied. Enable it in your device settings to attach a photo.',
            ),
          ),
        );
      return null;
    }
  }
}
