import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/utils/image_picker_util.dart';

class QrScannerCameraError extends StatelessWidget {
  final MobileScannerErrorCode errorCode;
  final VoidCallback? onRetry;
  const QrScannerCameraError({
    required this.errorCode,
    required this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final denied = errorCode == MobileScannerErrorCode.permissionDenied;
    return Center(
      child: SingleChildScrollView(
        padding: AppTheme.selectionSheetPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.videocam_off_outlined,
              color: AppTheme.scannerForeground,
            ),
            const SizedBox(height: AppTheme.inspectionSmallGap),
            Text(
              denied
                  ? 'Allow camera access in app settings to scan QR codes.'
                  : 'Unable to start the camera. Please try again.',
              textAlign: TextAlign.center,
              style: AppTheme.inspectionBodyStyle.copyWith(
                color: AppTheme.scannerForeground,
              ),
            ),
            const SizedBox(height: AppTheme.inspectionSmallGap),
            TextButton.icon(
              onPressed: denied
                  ? () => ImagePickerUtil.openPermissionSettings(
                      context,
                      permission: 'camera',
                    )
                  : onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.scannerForeground,
              ),
              icon: Icon(denied ? Icons.settings : Icons.refresh),
              label: Text(denied ? 'Open app settings' : 'Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
