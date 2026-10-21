import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/notification/domain/entities/notification_list_data.dart';
import 'package:marikina_market_mobile/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:marikina_market_mobile/features/notification/presentation/bloc/notification_event.dart';
import 'package:marikina_market_mobile/features/notification/presentation/bloc/notification_state.dart';
import 'package:marikina_market_mobile/features/notification/presentation/widgets/notification_list_sliver.dart';
import 'package:marikina_market_mobile/features/notification/presentation/widgets/notification_list_skeleton.dart';
import 'package:marikina_market_mobile/features/notification/presentation/widgets/notification_notice.dart';
import 'package:marikina_market_mobile/features/notification/presentation/widgets/vendor_notification_header.dart';

class NotificationPage extends StatefulWidget {
  final bool isVendor;
  const NotificationPage({this.isVendor = false, super.key});
  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  String _filter = 'All';
  final ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        _scrollController.position.pixels <= 0 ||
        _scrollController.position.extentAfter >
            AppTheme.notificationPageAheadExtent) {
      return;
    }
    final state = context.read<NotificationBloc>().state;
    if (state is NotificationLoaded &&
        state.hasMore &&
        !state.isLoadingMore &&
        !state.isRefreshing &&
        !state.isMarkingAll &&
        state.markingReadIds.isEmpty &&
        state.errorMessage == null) {
      context.read<NotificationBloc>().add(
        LoadNotifications(state.notifications.length, _filter),
      );
    }
  }

  void _changeFilter(String filter) {
    if (_filter == filter) return;
    setState(() => _filter = filter);
    context.read<NotificationBloc>().add(LoadNotifications(0, filter));
  }

  void _loadMore() {
    final state = context.read<NotificationBloc>().state;
    if (state is NotificationLoaded &&
        state.hasMore &&
        !state.isRefreshing &&
        !state.isLoadingMore &&
        !state.isMarkingAll &&
        state.markingReadIds.isEmpty) {
      context.read<NotificationBloc>().add(
        LoadNotifications(state.notifications.length, _filter),
      );
    }
  }

  void _retry() {
    final state = context.read<NotificationBloc>().state;
    context.read<NotificationBloc>().add(
      LoadNotifications(
        state is NotificationLoaded && state.isLoadMoreError
            ? state.notifications.length
            : 0,
        _filter,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.vendorNotificationBackground,
    body: SafeArea(
      child: BlocListener<NotificationBloc, NotificationState>(
        listenWhen: (previous, current) =>
            current is NotificationLoaded &&
            current.readErrorMessage != null &&
            (previous is! NotificationLoaded ||
                current.readErrorMessage != previous.readErrorMessage),
        listener: (context, state) {
          if (state is NotificationLoaded) {
            final message = state.readErrorMessage!;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  message.trim().isEmpty
                      ? 'Unable to mark this notification as read. Please try again.'
                      : message,
                ),
              ),
            );
          }
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppTheme.notificationMaxWidth,
            ),
            child: RefreshIndicator(
              onRefresh: () => context
                  .read<NotificationBloc>()
                  .refreshNotifications(_filter),
              child: CustomScrollView(
                key: const PageStorageKey('notifications'),
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: AppTheme.notificationCompactHeaderPadding,
                    sliver: SliverToBoxAdapter(
                      child: BlocBuilder<NotificationBloc, NotificationState>(
                        builder: (context, state) => VendorNotificationHeader(
                          isLoading:
                              state is NotificationInitial ||
                              state is NotificationLoading,
                          unreadCount: state is NotificationLoaded
                              ? state.unreadCount
                              : null,
                          unreadOnly: _filter == 'Unread',
                          isBusy:
                              state is! NotificationLoaded ||
                              state.isRefreshing ||
                              state.isLoadingMore ||
                              state.isMarkingAll ||
                              state.markingReadIds.isNotEmpty,
                          onToggleUnread: () => _changeFilter(
                            _filter == 'All' ? 'Unread' : 'All',
                          ),
                          onMarkAll: () => context.read<NotificationBloc>().add(
                            MarkAllAsRead(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  BlocBuilder<NotificationBloc, NotificationState>(
                    builder: (context, state) {
                      if (state is NotificationInitial ||
                          state is NotificationLoading) {
                        return SliverToBoxAdapter(
                          child: NotificationListSkeleton(isVendor: true),
                        );
                      }
                      if (state is NotificationLoaded) {
                        return SliverPadding(
                          padding: state.notifications.isNotEmpty
                              ? AppTheme.vendorNotificationListPadding
                              : AppTheme.notificationListPadding,
                          sliver: NotificationListSliver(
                            isVendor: widget.isVendor,
                            useVendorStyle: true,
                            isBusy: state.isMarkingAll,
                            data: NotificationListData(
                              notifications: state.notifications,
                              hasMore: state.hasMore,
                              isLoadingMore: state.isLoadingMore,
                              isRefreshing: state.isRefreshing,
                              errorMessage: state.errorMessage,
                              isLoadMoreError: state.isLoadMoreError,
                              markingReadIds: state.markingReadIds,
                            ),
                            onRead: (id) => context
                                .read<NotificationBloc>()
                                .add(MarkAsRead(id)),
                            onRetry: state.errorMessage != null
                                ? _retry
                                : _loadMore,
                          ),
                        );
                      }
                      if (state is NotificationFailed) {
                        return SliverPadding(
                          padding: AppTheme.notificationListPadding,
                          sliver: SliverToBoxAdapter(
                            child: NotificationNotice(
                              title: 'Notifications unavailable',
                              message: state.message.trim().isEmpty
                                  ? 'Please try again to load your notifications.'
                                  : state.message,
                              onRetry: _retry,
                            ),
                          ),
                        );
                      }
                      return const SliverToBoxAdapter(child: SizedBox.shrink());
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
