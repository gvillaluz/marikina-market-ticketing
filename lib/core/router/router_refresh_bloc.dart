import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_state.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<AuthState> _subscription;

  GoRouterRefreshStream(
    Stream<AuthState> stream, {
    void Function(AuthState)? onChanged,
  }) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((state) {
      onChanged?.call(state);
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
