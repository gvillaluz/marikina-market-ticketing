import 'package:marikina_market_mobile/core/errors/failure.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/profile/data/data_sources/qr_export_data_source.dart';
import 'package:marikina_market_mobile/features/profile/domain/repositories/qr_export_repository.dart';
import 'package:marikina_market_mobile/features/profile/domain/use_cases/export_qr_params.dart';

class QrExportRepositoryImpl implements QrExportRepository {
  final QrExportDataSource dataSource;
  QrExportRepositoryImpl(this.dataSource);
  @override
  Future<Result<bool>> exportQr(ExportQrParams params) async {
    try {
      return Result.success(await dataSource.exportQr(params));
    } catch (_) {
      return Result.failure(
        const ServerFailure('Unable to export your QR code. Please try again.'),
      );
    }
  }
}
