import 'package:marikina_market_mobile/core/errors/result.dart';
import '../entities/vendor_dashboard_summary.dart';
import '../repositories/vendor_dashboard_repository.dart';

class LoadVendorDashboardUseCase {
  final VendorDashboardRepository repository;
  const LoadVendorDashboardUseCase(this.repository);

  Future<Result<VendorDashboardSummary>> call() => repository.loadDashboard();
}
