import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'scanner_corner_pointer.dart';

class QrScannerOverlay extends StatelessWidget {
  final BarcodeCapture? capture;
  final DeviceOrientation orientation;
  final bool hasMultipleCodes;

  const QrScannerOverlay({
    required this.capture,
    required this.orientation,
    this.hasMultipleCodes = false,
    super.key,
  });

  // Match the installed scanner's BoxFit.cover projection, including its
  // landscape preview-size adjustment. Never paint barcode contents.
  static Rect? boundsFor(
    BarcodeCapture capture,
    Size viewport,
    DeviceOrientation orientation,
  ) {
    if (capture.barcodes.length != 1 ||
        capture.size.isEmpty ||
        viewport.isEmpty) {
      return null;
    }
    final corners = capture.barcodes.single.corners;
    if (corners.length < 4 ||
        corners.any((point) => !point.dx.isFinite || !point.dy.isFinite)) {
      return null;
    }
    final landscape =
        orientation == DeviceOrientation.landscapeLeft ||
        orientation == DeviceOrientation.landscapeRight;
    final preview = landscape ? capture.size.flipped : capture.size;
    if (!preview.width.isFinite ||
        !preview.height.isFinite ||
        !viewport.width.isFinite ||
        !viewport.height.isFinite) {
      return null;
    }
    final scale = math.max(
      viewport.width / preview.width,
      viewport.height / preview.height,
    );
    final offset = Offset(
      (viewport.width - preview.width * scale) / 2,
      (viewport.height - preview.height * scale) / 2,
    );
    final points = corners.map((point) => point * scale + offset).toList();
    if (points.any((point) => !point.dx.isFinite || !point.dy.isFinite)) {
      return null;
    }
    final rect = Rect.fromLTRB(
      points.map((point) => point.dx).reduce(math.min),
      points.map((point) => point.dy).reduce(math.min),
      points.map((point) => point.dx).reduce(math.max),
      points.map((point) => point.dy).reduce(math.max),
    );
    if (rect.isEmpty) return null;
    final visible = rect
        .inflate(AppTheme.scannerBorderPadding)
        .intersect(
          (Offset.zero & viewport).deflate(AppTheme.scannerBorderWidth / 2),
        );
    return visible.isEmpty ? null : visible;
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final guideSize = math.min(
          AppTheme.scannerGuideSize,
          math.min(size.width, size.height) *
              AppTheme.scannerGuideViewportRatio,
        );
        final guide = Rect.fromCenter(
          center: size.center(Offset.zero),
          width: guideSize,
          height: guideSize,
        );
        final detected = capture == null
            ? null
            : boundsFor(capture!, size, orientation);
        return TweenAnimationBuilder<Rect?>(
          tween: RectTween(begin: guide, end: detected ?? guide),
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : AppTheme.buttonAnimationDuration,
          curve: Curves.easeOutCubic,
          builder: (context, rect, _) => Stack(
            children: [
              Positioned.fromRect(
                rect: rect!,
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: ScannerCornersPainter(
                      color: hasMultipleCodes
                          ? AppTheme.scannerNoticeColor
                          : detected != null
                          ? AppTheme.scannerDetectedColor
                          : AppTheme.scannerForeground,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
