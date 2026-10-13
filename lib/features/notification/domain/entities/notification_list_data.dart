import 'package:marikina_market_mobile/features/notification/domain/entities/notification_summary.dart';

class NotificationListData {
  final List<NotificationSummary> notifications;
  final bool hasMore;
  final bool isLoadingMore;
  final String? errorMessage;
  final bool isLoadMoreError;
  final bool isRefreshing;
  final Set<int> markingReadIds;

  const NotificationListData({
    required this.notifications,
    required this.hasMore,
    required this.isLoadingMore,
    required this.errorMessage,
    required this.isLoadMoreError,
    this.isRefreshing = false,
    this.markingReadIds = const {},
  });
}
