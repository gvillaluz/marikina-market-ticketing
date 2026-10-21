// core/notifications/notification_listener_service.dart
import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/router/mobile_route_access.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'in_app_notification_overlay.dart';

class NotificationListenerService {
  final GoRouter router;
  final AuthBloc authBloc;
  final FirebaseMessaging? _messaging;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<String>? _tokenSubscription;

  NotificationListenerService(
    this.router,
    this.authBloc, {
    FirebaseMessaging? messaging,
  }) : _messaging = messaging;

  void init() {
    if (_tokenSubscription != null) return;
    _messageSubscription = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
    );
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _handleNotificationTap,
    );
    _tokenSubscription = (_messaging ?? FirebaseMessaging.instance)
        .onTokenRefresh
        .listen(
          (_) {
            if (!authBloc.isClosed) {
              authBloc.add(RegisterDeviceTokenRequested());
            }
          },
          onError: (Object _) {
            // Reconnect and periodic auth sync read the current token again.
          },
        );
  }

  Future<void> dispose() async {
    await _tokenSubscription?.cancel();
    await _messageSubscription?.cancel();
    await _openedSubscription?.cancel();
    _tokenSubscription = null;
    _messageSubscription = null;
    _openedSubscription = null;
  }

  Future<void> handleInitialMessage() async {
    final initialMessage = await (_messaging ?? FirebaseMessaging.instance)
        .getInitialMessage();
    if (initialMessage != null) {
      await _handleNotificationTap(initialMessage);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final state = authBloc.state;
    if (state is! Authenticated ||
        MobileRouteAccess.notificationLocation(state, null) == null) {
      return;
    }
    final overlayState =
        router.routerDelegate.navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    InAppNotificationOverlay.show(
      overlayState,
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      onTap: () {
        final currentState = authBloc.state;
        if (currentState is! Authenticated ||
            currentState.user.userId != state.user.userId ||
            currentState.user.role != state.user.role) {
          return;
        }
        _navigateToTicket(message);
      },
    );
  }

  Future<void> _handleNotificationTap(RemoteMessage message) async {
    if (authBloc.state is AuthInitial || authBloc.state is AuthLoading) {
      try {
        await authBloc.stream.firstWhere(
          (state) => state is! AuthInitial && state is! AuthLoading,
        );
      } on StateError {
        return;
      }
    }
    _navigateToTicket(message);
  }

  void _navigateToTicket(RemoteMessage message) {
    final location = MobileRouteAccess.notificationLocation(
      authBloc.state,
      message.data['ticketId'],
    );
    if (location == null) return;
    if (location == Routes.vendorNotifications) {
      router.go(location);
    } else {
      router.push(location);
    }
  }
}
