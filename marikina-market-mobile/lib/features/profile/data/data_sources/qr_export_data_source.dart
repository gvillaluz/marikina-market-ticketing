import 'package:marikina_market_mobile/features/profile/domain/use_cases/export_qr_params.dart';
import 'dart:ui';
import 'package:file_saver/file_saver.dart';
import 'package:share_plus/share_plus.dart';

class QrExportDataSource {
  Future<bool> exportQr(ExportQrParams params) async {
    final name =
        'vendor-qr-${params.businessId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')}';
    if (!params.share) {
      final path = await FileSaver.instance.saveAs(
        name: name,
        bytes: params.pngBytes,
        fileExtension: 'png',
        mimeType: MimeType.png,
      );
      return path != null && path.isNotEmpty;
    }
    final origin = params.origin;
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            params.pngBytes,
            mimeType: 'image/png',
            name: '$name.png',
          ),
        ],
        fileNameOverrides: ['$name.png'],
        sharePositionOrigin: origin == null
            ? null
            : Rect.fromLTWH(origin.x, origin.y, origin.width, origin.height),
      ),
    );
    // Some platforms cannot report a result; avoid claiming confirmed delivery.
    return result.status == ShareResultStatus.success;
  }
}
