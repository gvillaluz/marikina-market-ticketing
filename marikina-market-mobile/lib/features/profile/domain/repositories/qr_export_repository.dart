import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/profile/domain/use_cases/export_qr_params.dart';

abstract class QrExportRepository {
  Future<Result<bool>> exportQr(ExportQrParams params);
}
