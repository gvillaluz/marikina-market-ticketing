import 'dart:typed_data';

class ExportQrParams {
  final Uint8List pngBytes;
  final String businessId;
  final bool share;
  final ({double x, double y, double width, double height})? origin;
  const ExportQrParams({
    required this.pngBytes,
    required this.businessId,
    required this.share,
    this.origin,
  });
}
