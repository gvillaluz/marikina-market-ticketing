import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/features/notification/presentation/bloc/unread_count_bloc.dart';
import 'package:marikina_market_mobile/features/notification/presentation/bloc/unread_count_event.dart';
import 'package:marikina_market_mobile/features/notification/presentation/widgets/notification_unread_badge.dart';

class NotificationBellButton extends StatefulWidget {
  const NotificationBellButton({super.key});

  @override
  State<NotificationBellButton> createState() => _NotificationBellButtonState();
}

class _NotificationBellButtonState extends State<NotificationBellButton> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _refresh);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _refresh() => context.read<UnreadCountBloc>().add(LoadUnreadCount());

  Future<void> _openNotifications() async {
    await context.pushNamed(Routes.notificationsName);
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final count = context.select<UnreadCountBloc, int>(
      (bloc) => bloc.state.count ?? 0,
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: count > 0 ? 'Notifications, $count unread' : 'Notifications',
          onPressed: _openNotifications,
          style: IconButton.styleFrom(
            foregroundColor: AppColors.primary,
            backgroundColor: AppColors.primary.withValues(alpha: .08),
            shape: const CircleBorder(),
          ),
          icon: const Icon(Icons.notifications_outlined, size: 24),
        ),
        if (count > 0)
          Positioned(
            top: 0,
            right: 0,
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: NotificationUnreadBadge(count: count),
              ),
            ),
          ),
      ],
    );
  }
}
