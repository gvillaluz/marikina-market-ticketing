// core/notifications/notification_listener_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/router/mobile_route_access.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'in_app_notification_overlay.dart';

class NotificationListenerService {
  final GoRouter router;
  final AuthBloc authBloc;

  NotificationListenerService(this.router, this.authBloc);

  void init() {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  Future<void> handleInitialMessage() async {
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      if (authBloc.state is AuthInitial || authBloc.state is AuthLoading) {
        try {
          await authBloc.stream.firstWhere(
            (state) => state is! AuthInitial && state is! AuthLoading,
          );
        } on StateError {
          return;
        }
      }
      _navigateToTicket(initialMessage);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (MobileRouteAccess.notificationLocation(authBloc.state, null) == null) {
      return;
    }
    final overlayState =
        router.routerDelegate.navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    InAppNotificationOverlay.show(
      overlayState,
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      onTap: () => _navigateToTicket(message),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
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
