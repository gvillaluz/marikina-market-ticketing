import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/usecases/usecase.dart';
import 'package:marikina_market_mobile/features/profile/domain/repositories/qr_export_repository.dart';
import 'package:marikina_market_mobile/features/profile/domain/use_cases/export_qr_params.dart';

class ExportQrUseCase extends UseCase<bool, ExportQrParams> {
  final QrExportRepository repository;
  ExportQrUseCase(this.repository);
  @override
  Future<Result<bool>> call(ExportQrParams params) =>
      repository.exportQr(params);
}
