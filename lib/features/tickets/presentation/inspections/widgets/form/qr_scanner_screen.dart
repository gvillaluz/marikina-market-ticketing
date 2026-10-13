import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/vendor_summary.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_event.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_state.dart';
import 'qr_scanner_overlay.dart';
import 'qr_scanner_camera_controls.dart';
import 'qr_scanner_camera_error.dart';
import 'qr_scanner_status.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});
  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    formats: const [BarcodeFormat.qrCode],
  );
  BarcodeCapture? _capture;
  bool _isScanned = false;
  bool _multipleDetected = false;
  bool _cameraActionPending = false;
  String? _cameraActionMessage;
  Timer? _returnTimer;
  Timer? _noticeTimer;
  DateTime? _detectedAt;

  @override
  void initState() {
    super.initState();
    unawaited(_setWakelock(true));
  }

  Future<void> _setWakelock(bool enabled) async {
    try {
      await WakelockPlus.toggle(enable: enabled);
    } on PlatformException {
      // Keeping the display awake is optional; camera use can continue.
    } on MissingPluginException {
      // Some platforms do not provide a screen-wake plugin.
    }
  }

  Future<void> _releaseCamera() async {
    try {
      await _controller.dispose();
    } on MobileScannerException {
      // The camera may already have been released by the platform.
    } on PlatformException {
      // There is no active screen on which to present disposal errors.
    } on MissingPluginException {
      // No native camera is available on this platform.
    } finally {
      await _setWakelock(false);
    }
  }

  @override
  void dispose() {
    _returnTimer?.cancel();
    _noticeTimer?.cancel();
    unawaited(_releaseCamera());
    super.dispose();
  }

  Future<void> _cameraAction(Future<void> Function() action) async {
    if (_cameraActionPending || _isScanned) return;
    setState(() {
      _cameraActionPending = true;
      _cameraActionMessage = null;
      _capture = null;
    });
    try {
      await action();
    } on MobileScannerException {
      if (mounted) {
        setState(
          () => _cameraActionMessage =
              'Unable to change the camera. Please try again.',
        );
      }
    } on PlatformException {
      if (mounted) {
        setState(
          () => _cameraActionMessage =
              'Camera controls are unavailable. Please try again.',
        );
      }
    } on MissingPluginException {
      if (mounted) {
        setState(
          () => _cameraActionMessage =
              'The camera is unavailable on this device.',
        );
      }
    } finally {
      if (mounted) setState(() => _cameraActionPending = false);
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (!mounted || _isScanned || _cameraActionPending) return;
    final barcodes = capture.barcodes
        .where((barcode) => barcode.rawValue?.trim().isNotEmpty ?? false)
        .toList();
    if (barcodes.isEmpty) return;
    _noticeTimer?.cancel();
    if (barcodes.length > 1) {
      if (!_multipleDetected) {
        setState(() {
          _multipleDetected = true;
          _capture = null;
        });
      }
      _noticeTimer = Timer(AppTheme.scannerMultipleCodeNoticeDuration, () {
        if (mounted && !_isScanned) setState(() => _multipleDetected = false);
      });
      return;
    }
    setState(() {
      _isScanned = true;
      _multipleDetected = false;
      _cameraActionMessage = null;
      _capture = BarcodeCapture(barcodes: barcodes, size: capture.size);
      _detectedAt = DateTime.now();
    });
    context.read<InspectionBloc>().add(
      SearchByCodeRequested(barcodes.single.rawValue!),
    );
  }

  void _returnVendor(VendorSummary vendor) {
    // Allow the fitted border to settle even when the lookup returns quickly.
    final elapsed = DateTime.now().difference(_detectedAt ?? DateTime.now());
    final remaining = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppTheme.buttonAnimationDuration - elapsed;
    _returnTimer?.cancel();
    _returnTimer = Timer(remaining.isNegative ? Duration.zero : remaining, () {
      if (mounted) Navigator.pop(context, vendor);
    });
  }

  void _scanAgain() {
    setState(() {
      _isScanned = false;
      _capture = null;
      _multipleDetected = false;
      _cameraActionMessage = null;
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocListener<InspectionBloc, InspectionState>(
    listener: (context, state) {
      if (_isScanned && state is InspectionVendorSelected) {
        _returnVendor(state.vendor);
      }
    },
    child: Scaffold(
      backgroundColor: AppTheme.scannerBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.scannerBackground,
        foregroundColor: AppTheme.scannerForeground,
        iconTheme: const IconThemeData(color: AppTheme.scannerForeground),
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back, color: AppTheme.scannerForeground),
        ),
        title: Text(
          'Scan QR code',
          style: AppTheme.inspectionHeadingStyle.copyWith(
            color: AppTheme.scannerForeground,
          ),
        ),
        actions: [
          QrScannerCameraControls(
            controller: _controller,
            isBusy: _isScanned || _cameraActionPending,
            onToggleTorch: () => _cameraAction(_controller.toggleTorch),
            onSwitchCamera: () =>
                _cameraAction(() => _controller.switchCamera()),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => MobileScanner(
                controller: _controller,
                fit: BoxFit.cover,
                scanWindow: Offset.zero & constraints.biggest,
                onDetect: _onDetect,
                onDetectError: (_, _) {
                  if (mounted) {
                    setState(
                      () => _cameraActionMessage =
                          'Unable to read that code. Hold it steady and try again.',
                    );
                  }
                },
                errorBuilder: (context, error) => QrScannerCameraError(
                  errorCode: error.errorCode,
                  onRetry: _cameraActionPending
                      ? null
                      : () => _cameraAction(_controller.start),
                ),
                overlayBuilder: (context, _) =>
                    ValueListenableBuilder<MobileScannerState>(
                      valueListenable: _controller,
                      builder: (context, state, _) => QrScannerOverlay(
                        capture: _capture,
                        orientation: state.deviceOrientation,
                        hasMultipleCodes: _multipleDetected,
                      ),
                    ),
              ),
            ),
          ),
          BlocBuilder<InspectionBloc, InspectionState>(
            builder: (context, state) {
              final failed = _isScanned && state is InspectionSearchError;
              final loading = _isScanned && state is InspectionSearchLoading;
              final message = failed
                  ? (state.error.trim().isEmpty
                        ? 'Unable to find this vendor. Please try again.'
                        : state.error)
                  : _cameraActionMessage ??
                        (loading
                            ? 'QR code detected. Checking the vendor...'
                            : _multipleDetected
                            ? 'Multiple QR codes detected. Move closer to isolate one code.'
                            : _isScanned
                            ? 'QR code detected.'
                            : 'Point the camera at a vendor QR code anywhere in the preview.');
              return QrScannerStatus(
                message: message,
                isLoading: loading,
                onRetry: failed || _cameraActionMessage != null
                    ? _scanAgain
                    : null,
              );
            },
          ),
        ],
      ),
    ),
  );
}
