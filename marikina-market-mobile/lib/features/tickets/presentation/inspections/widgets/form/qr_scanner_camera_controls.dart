import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class QrScannerCameraControls extends StatelessWidget {
  final MobileScannerController controller;
  final bool isBusy;
  final VoidCallback onToggleTorch;
  final VoidCallback onSwitchCamera;

  const QrScannerCameraControls({
    required this.controller,
    required this.isBusy,
    required this.onToggleTorch,
    required this.onSwitchCamera,
    super.key,
  });

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<MobileScannerState>(
        valueListenable: controller,
        builder: (context, state, _) {
          final ready =
              state.isInitialized &&
              state.isRunning &&
              state.error == null &&
              !isBusy;
          final torchOn = state.torchState == TorchState.on;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: torchOn ? 'Turn flash off' : 'Turn flash on',
                isSelected: torchOn,
                color: torchOn
                    ? AppTheme.scannerFlashColor
                    : AppTheme.scannerForeground,
                onPressed: ready && state.torchState != TorchState.unavailable
                    ? onToggleTorch
                    : null,
                icon: Icon(torchOn ? Icons.flash_on : Icons.flash_off),
              ),
              IconButton(
                tooltip: 'Switch camera',
                color: AppTheme.scannerForeground,
                onPressed: ready && (state.availableCameras ?? 0) > 1
                    ? onSwitchCamera
                    : null,
                icon: const Icon(Icons.cameraswitch_outlined),
              ),
            ],
          );
        },
      );
}
