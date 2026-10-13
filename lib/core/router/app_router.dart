import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/router/app_routes.dart';
import 'package:marikina_market_mobile/core/router/mobile_route_access.dart';
import 'package:marikina_market_mobile/core/router/router_refresh_bloc.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/features/auth/domain/enums/role.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_state.dart';

class AppRouter {
  final AuthBloc authBloc;
  late final GoRouter router;
  late final ValueNotifier<RoutingConfig> _routingConfig;
  late final GoRouterRefreshStream _refresh;
  (int, Role)? _sessionIdentity;

  AppRouter({required this.authBloc}) {
    _sessionIdentity = _identity(authBloc.state);
    _routingConfig = ValueNotifier(_configuration());
    _refresh = GoRouterRefreshStream(
      authBloc.stream,
      onChanged: _onAuthChanged,
    );
    router = GoRouter.routingConfig(
      routingConfig: _routingConfig,
      restorationScopeId: 'router',
      initialLocation: Routes.splash,
      refreshListenable: _refresh,
    );
  }

  (int, Role)? _identity(AuthState state) =>
      state is Authenticated ? (state.user.userId, state.user.role) : null;

  RoutingConfig _configuration() => RoutingConfig(
    routes: buildAppRoutes(sessionKey: _sessionIdentity?.toString()),
    redirect: (context, state) =>
        MobileRouteAccess.redirect(authBloc.state, state.uri.path),
  );

  void _onAuthChanged(AuthState state) {
    if (state is AuthChangePasswordLoading ||
        state is AuthChangePasswordError ||
        state is AuthChangePasswordNetworkError) {
      return;
    }
    final identity = _identity(state);
    if (identity == _sessionIdentity) return;
    final previousIdentity = _sessionIdentity;
    _sessionIdentity = identity;
    // Fresh shell routes discard retained branch stacks and data between
    // accounts/roles. Ordinary profile updates preserve navigation state.
    _routingConfig.value = _configuration();
    if (identity != null && previousIdentity != null) {
      router.go(MobileRouteAccess.redirect(state, Routes.login)!);
    }
  }

  void dispose() {
    router.dispose();
    _refresh.dispose();
    _routingConfig.dispose();
  }
}
