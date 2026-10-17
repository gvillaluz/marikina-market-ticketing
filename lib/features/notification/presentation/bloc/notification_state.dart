import 'package:marikina_market_mobile/features/notification/domain/entities/notification_summary.dart';

abstract class NotificationState {}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationFailed extends NotificationState {
  final String message;
  NotificationFailed(this.message);
}

class NotificationLoaded extends NotificationState {
  final List<NotificationSummary> notifications;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isRefreshing;
  final String? errorMessage;
  final bool isLoadMoreError;
  final Set<int> markingReadIds;
  final String? readErrorMessage;
  final int? unreadCount;
  final bool isMarkingAll;

  NotificationLoaded(
    this.notifications,
    this.hasMore, {
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.errorMessage,
    this.isLoadMoreError = false,
    this.markingReadIds = const {},
    this.readErrorMessage,
    this.unreadCount,
    this.isMarkingAll = false,
  });

  NotificationLoaded copyWith({
    List<NotificationSummary>? notifications,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isRefreshing,
    String? errorMessage,
    bool? isLoadMoreError,
    bool clearErrorMessage = false,
    Set<int>? markingReadIds,
    String? readErrorMessage,
    bool clearReadErrorMessage = false,
    int? unreadCount,
    bool clearUnreadCount = false,
    bool? isMarkingAll,
  }) {
    return NotificationLoaded(
      notifications ?? this.notifications,
      hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      isLoadMoreError: isLoadMoreError ?? this.isLoadMoreError,
      markingReadIds: markingReadIds ?? this.markingReadIds,
      readErrorMessage: clearReadErrorMessage
          ? null
          : readErrorMessage ?? this.readErrorMessage,
      unreadCount: clearUnreadCount ? null : unreadCount ?? this.unreadCount,
      isMarkingAll: isMarkingAll ?? this.isMarkingAll,
    );
  }
}
