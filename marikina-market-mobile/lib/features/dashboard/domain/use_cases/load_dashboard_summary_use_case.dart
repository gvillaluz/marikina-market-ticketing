import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:marikina_market_mobile/features/dashboard/domain/repositories/dashboard_repository.dart';

class LoadDashboardSummaryUseCase {
  final DashboardRepository _repository;
  LoadDashboardSummaryUseCase(this._repository);

  Future<Result<DashboardSummary>> call() async {
    return await _repository.loadDashboard();
  }
}