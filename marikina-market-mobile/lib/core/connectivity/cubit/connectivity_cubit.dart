import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/connectivity/connectivity_status.dart';
import 'package:marikina_market_mobile/core/network/network_info.dart';

class ConnectivityCubit extends Cubit<ConnectivityStatus> {
  final NetworkInfo networkInfo;
  late final StreamSubscription<List<ConnectivityResult>> subscription;

  ConnectivityCubit(this.networkInfo) : super(ConnectivityStatus.online) {
    subscription = networkInfo.onConnectivityChanged.listen(_updateStatus);
    _checkInitialStatus();
  }

  Future<void> _checkInitialStatus() async {
    final bool hasInternet = await networkInfo.hasInternetAccess;
    emit(hasInternet ? ConnectivityStatus.online : ConnectivityStatus.offline);
  }

  void _updateStatus(List<ConnectivityResult> results) async {
    final ConnectivityResult result = results.first;

     if (result == ConnectivityResult.none) {
      emit(ConnectivityStatus.offline);
      return;
    }

    final bool hasInternet = await networkInfo.hasInternetAccess;
    emit(hasInternet ? ConnectivityStatus.online : ConnectivityStatus.offline);
  }

  @override
  Future<void> close() {
    subscription.cancel();
    return super.close();
  }
}