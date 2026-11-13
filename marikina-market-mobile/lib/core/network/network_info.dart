import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<List<ConnectivityResult>> get onConnectivityChanged;
  Future<bool> get hasInternetAccess;
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;

  NetworkInfoImpl(this.connectivity);

  @override
  Future<bool> get isConnected async {
    final List<ConnectivityResult> results = await connectivity.checkConnectivity();
    final ConnectivityResult result = results.first;

    if (result == ConnectivityResult.none) {
      return false;
    } else {
      return true;
    }
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => connectivity.onConnectivityChanged;

  @override
  Future<bool> get hasInternetAccess async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    }
  }
}