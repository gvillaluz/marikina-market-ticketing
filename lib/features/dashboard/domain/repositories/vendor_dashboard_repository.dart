import 'package:marikina_market_mobile/core/errors/result.dart';
import '../entities/vendor_dashboard_summary.dart';

abstract class VendorDashboardRepository {
  Future<Result<VendorDashboardSummary>> loadDashboard();
}
