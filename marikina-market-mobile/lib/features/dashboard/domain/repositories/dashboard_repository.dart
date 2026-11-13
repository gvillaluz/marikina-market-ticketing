import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/dashboard/domain/entities/dashboard_summary.dart';

abstract class DashboardRepository {
  Future<Result<DashboardSummary>> loadDashboard();
}