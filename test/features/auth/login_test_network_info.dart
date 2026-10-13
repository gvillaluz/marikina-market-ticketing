import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:marikina_market_mobile/core/network/network_info.dart';

class LoginTestNetworkInfo implements NetworkInfo {
  @override
  Future<bool> get hasInternetAccess async => false;
  @override
  Future<bool> get isConnected async => false;
  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      const Stream.empty();
}
