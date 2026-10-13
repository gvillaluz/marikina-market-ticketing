import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/notification/domain/entities/notification_summary.dart';
import 'package:marikina_market_mobile/features/notification/domain/use_cases/load_notifications_use_case.dart';
import 'package:marikina_market_mobile/features/notification/domain/use_cases/mark_as_read_use_case.dart';
import 'package:marikina_market_mobile/features/notification/presentation/bloc/notification_event.dart';
import 'package:marikina_market_mobile/features/notification/presentation/bloc/notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final LoadNotificationsUseCase loadNotificationsUseCase;
  final MarkAsReadUseCase markAsReadUseCase;
  List<NotificationSummary> _notifications = [];
  String _filter = 'All';
  bool _hasMore = false;
  bool _isLoadingMore = false;
  bool _isRefreshing = false;
  bool _hasLoaded = false;
  final Set<int> _pendingReadIds = {};
  int _listRequestId = 0;

  NotificationBloc({
    required this.loadNotificationsUseCase,
    required this.markAsReadUseCase,
  }) : super(NotificationInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<MarkAsRead>(_onMarkAsRead);
  }

  Future<void> refreshNotifications(String filter) async {
    if (isClosed) return;
    final finished = stream.firstWhere(
      (state) =>
          state is NotificationFailed ||
          state is NotificationLoaded &&
              !state.isRefreshing &&
              !state.isLoadingMore,
    );
    add(LoadNotifications(0, filter));
    try {
      await finished;
    } on StateError {
      /* Screen closed. */
    }
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    final isLoadMore = event.offset > 0;
    if (isLoadMore) {
      final current = state;
      if (_isLoadingMore ||
          _isRefreshing ||
          current is! NotificationLoaded ||
          !current.hasMore ||
          !_hasMore ||
          event.offset != _notifications.length ||
          event.filter != _filter) {
        return;
      }
      _isLoadingMore = true;
      emit(current.copyWith(isLoadingMore: true, clearErrorMessage: true));
    } else {
      final filterChanged = event.filter != _filter;
      if (!filterChanged && _isRefreshing) return;
      _isRefreshing = true;
      _filter = event.filter;
      _listRequestId++;
      _isLoadingMore = false;
      if (filterChanged) {
        _hasLoaded = false;
        _notifications = [];
        _hasMore = false;
      }
      if (!_hasLoaded) {
        emit(NotificationLoading());
      } else {
        emit(
          NotificationLoaded(
            _notifications,
            _hasMore,
            isRefreshing: true,
            markingReadIds: Set.unmodifiable(_pendingReadIds),
          ),
        );
      }
    }

    final requestId = _listRequestId;
    final result = await loadNotificationsUseCase(event.offset, event.filter);
    if (requestId != _listRequestId || emit.isDone) return;
    _isRefreshing = false;

    switch (result) {
      case Success(:final data):
        _notifications = event.offset == 0
            ? data.items
            : [..._notifications, ...data.items];
        _hasMore = data.hasMore && data.items.isNotEmpty;
        _isLoadingMore = false;
        _hasLoaded = true;
        emit(
          NotificationLoaded(
            _notifications,
            _hasMore,
            markingReadIds: Set.unmodifiable(_pendingReadIds),
          ),
        );
        break;

      case ResultFailure(failure: final failure):
        _isLoadingMore = false;
        if (!_hasLoaded) {
          emit(NotificationFailed(failure.message));
        } else {
          emit(
            NotificationLoaded(
              _notifications,
              _hasMore,
              errorMessage: failure.message,
              isLoadMoreError: isLoadMore,
              markingReadIds: Set.unmodifiable(_pendingReadIds),
            ),
          );
        }
    }
  }

  Future<void> _onMarkAsRead(
    MarkAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    final current = state;
    if (current is! NotificationLoaded ||
        _pendingReadIds.contains(event.id) ||
        !current.notifications.any(
          (item) => item.notificationId == event.id && !item.isRead,
        )) {
      return;
    }
    _pendingReadIds.add(event.id);
    emit(
      current.copyWith(
        markingReadIds: Set.unmodifiable(_pendingReadIds),
        clearReadErrorMessage: true,
      ),
    );
    final result = await markAsReadUseCase(event.id);
    _pendingReadIds.remove(event.id);
    if (emit.isDone) return;
    final latest = state;
    if (latest is! NotificationLoaded) return;
    if (result case ResultFailure(:final failure)) {
      emit(
        latest.copyWith(
          markingReadIds: Set.unmodifiable(_pendingReadIds),
          readErrorMessage: failure.message,
        ),
      );
      return;
    }
    _notifications = latest.notifications
        .map(
          (n) => n.notificationId != event.id
              ? n
              : NotificationSummary(
                  notificationId: n.notificationId,
                  enforcerId: n.enforcerId,
                  ticketId: n.ticketId,
                  controlNumber: n.controlNumber,
                  tradeName: n.tradeName,
                  marketSection: n.marketSection,
                  penaltyType: n.penaltyType,
                  totalFineAmount: n.totalFineAmount,
                  dueDate: n.dueDate,
                  status: n.status,
                  message: n.message,
                  isRead: true,
                  createdAt: n.createdAt,
                ),
        )
        .where((n) => _filter != 'Unread' || !n.isRead)
        .toList();
    emit(
      latest.copyWith(
        notifications: _notifications,
        markingReadIds: Set.unmodifiable(_pendingReadIds),
        clearReadErrorMessage: true,
      ),
    );
  }
}
