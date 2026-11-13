// core/notifications/in_app_notification_overlay.dart
import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/notification/widgets/in_app_notification_banner.dart';

class InAppNotificationOverlay {
  static OverlayEntry? _currentEntry;
  static final GlobalKey<State<InAppNotificationBanner>> _bannerKey = GlobalKey();

  static void show(
    OverlayState overlayState, {
    required String title,
    required String body,
    VoidCallback? onTap,
  }) {
    _currentEntry?.remove();

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: InAppNotificationBanner(
          key: _bannerKey,
          title: title,
          body: body,
          onTap: onTap,
          onDismiss: () {
            entry.remove();
            if (_currentEntry == entry) _currentEntry = null;
          },
        ),
      ),
    );

    _currentEntry = entry;
    overlayState.insert(entry);

    Future.delayed(const Duration(seconds: 4), () {
      if (_currentEntry == entry) {
        (_bannerKey.currentState as dynamic)?.dismiss();
      }
    });
  }
}