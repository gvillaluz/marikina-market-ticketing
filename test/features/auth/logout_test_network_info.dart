import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:marikina_market_mobile/core/network/network_info.dart';

class LogoutTestNetworkInfo implements NetworkInfo {
  bool online;
  final Stream<List<ConnectivityResult>> changes;
  LogoutTestNetworkInfo({
    this.online = true,
    this.changes = const Stream.empty(),
  });

  @override
  Future<bool> get hasInternetAccess async => online;
  @override
  Future<bool> get isConnected async => online;
  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => changes;
}
