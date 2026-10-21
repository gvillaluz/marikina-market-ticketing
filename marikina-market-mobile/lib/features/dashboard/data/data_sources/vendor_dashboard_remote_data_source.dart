import 'package:marikina_market_mobile/core/network/client.dart';
import '../models/vendor_dashboard_model.dart';

class VendorDashboardRemoteDataSource {
  final ApiClient client;
  const VendorDashboardRemoteDataSource(this.client);

  Future<VendorDashboardModel> loadDashboard() async {
    final response = await client.get('/vendor/dashboard');
    return VendorDashboardModel(response.data as Map<String, Object?>);
  }
}
