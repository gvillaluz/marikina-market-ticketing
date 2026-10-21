import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/notification/domain/entities/notification_summary.dart';
import 'package:marikina_market_mobile/features/notification/domain/use_cases/load_notifications_use_case.dart';
import 'package:marikina_market_mobile/features/notification/domain/use_cases/mark_as_read_use_case.dart';
import 'package:marikina_market_mobile/features/notification/domain/use_cases/load_unread_count_use_case.dart';
import 'package:marikina_market_mobile/features/notification/presentation/bloc/notification_event.dart';
import 'package:marikina_market_mobile/features/notification/presentation/bloc/notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final LoadNotificationsUseCase loadNotificationsUseCase;
  final MarkAsReadUseCase markAsReadUseCase;
  final LoadUnreadCountUseCase? loadUnreadCountUseCase;
  int? _unreadCount;
  bool _isMarkingAll = false;
  List<NotificationSummary> _notifications = [];
  String _filter = 'All';
  bool _hasMore = false;
  bool _isLoadingMore = false;
  bool _isRefreshing = false;
  bool _hasLoaded = false;
  final Set<int> _pendingReadIds = {};
  int _listRequestId = 0;
  int _nextOffset = 0;

  NotificationBloc({
    required this.loadNotificationsUseCase,
    required this.markAsReadUseCase,
    this.loadUnreadCountUseCase,
  }) : super(NotificationInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<MarkAsRead>(_onMarkAsRead);
    on<MarkAllAsRead>(_onMarkAllAsRead);
  }

  Future<void> refreshNotifications(String filter) async {
    if (isClosed || _isMarkingAll || _pendingReadIds.isNotEmpty) return;
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
    if (_isMarkingAll || _pendingReadIds.isNotEmpty) return;
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
            unreadCount: _unreadCount,
          ),
        );
      }
    }

    final requestId = _listRequestId;
    final result = await loadNotificationsUseCase(
      isLoadMore ? _nextOffset : 0,
      event.filter,
    );
    if (requestId != _listRequestId || emit.isDone) return;

    switch (result) {
      case Success(:final data):
        String? countError;
        if (loadUnreadCountUseCase case final useCase?) {
          final count = await useCase();
          if (requestId != _listRequestId || emit.isDone) return;
          switch (count) {
            case Success(:final data):
              _unreadCount = data;
            case ResultFailure(:final failure):
              _unreadCount = null;
              countError = failure.message;
          }
        }
        _isRefreshing = false;
        _nextOffset = isLoadMore
            ? _nextOffset + data.items.length
            : data.items.length;
        final seen = <int>{};
        _notifications =
            (isLoadMore ? [..._notifications, ...data.items] : data.items)
                .where((item) => seen.add(item.notificationId))
                .toList();
        _hasMore = data.hasMore && data.items.isNotEmpty;
        _isLoadingMore = false;
        _hasLoaded = true;
        emit(
          NotificationLoaded(
            _notifications,
            _hasMore,
            markingReadIds: Set.unmodifiable(_pendingReadIds),
            unreadCount: _unreadCount,
            errorMessage: countError,
          ),
        );
        break;

      case ResultFailure(failure: final failure):
        _isRefreshing = false;
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
              unreadCount: _unreadCount,
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
        _isMarkingAll ||
        _isRefreshing ||
        _isLoadingMore ||
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
                  isWarning: n.isWarning,
                ),
        )
        .where((n) => _filter != 'Unread' || !n.isRead)
        .toList();
    if (_unreadCount != null && _unreadCount! > 0) {
      _unreadCount = _unreadCount! - 1;
    }
    emit(
      latest.copyWith(
        notifications: _notifications,
        markingReadIds: Set.unmodifiable(_pendingReadIds),
        clearReadErrorMessage: true,
        unreadCount: _unreadCount,
      ),
    );
    // Removing an unread row shifts every following offset on the server.
    if (loadUnreadCountUseCase != null && _filter == 'Unread') {
      await _onLoadNotifications(LoadNotifications(0, _filter), emit);
    }
  }

  Future<void> _onMarkAllAsRead(
    MarkAllAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    final current = state;
    if (loadUnreadCountUseCase == null ||
        current is! NotificationLoaded ||
        _isMarkingAll ||
        _isRefreshing ||
        _isLoadingMore ||
        _pendingReadIds.isNotEmpty ||
        current.unreadCount == 0) {
      return;
    }
    _isMarkingAll = true;
    emit(current.copyWith(isMarkingAll: true, clearReadErrorMessage: true));
    final ids = <int>{};
    String? error;
    var offset = 0;
    // Snapshot before writing: paging through a shrinking Unread list skips rows.
    while (!emit.isDone && !isClosed) {
      final result = await loadNotificationsUseCase(offset, 'Unread');
      if (emit.isDone || isClosed) return;
      if (result case ResultFailure(:final failure)) {
        error = failure.message;
        break;
      }
      if (result case Success(:final data)) {
        final before = ids.length;
        ids.addAll(
          data.items.where((n) => !n.isRead).map((n) => n.notificationId),
        );
        if (!data.hasMore) break;
        if (data.items.isEmpty || ids.length == before) {
          error =
              'Notifications changed while loading. Please refresh and try again.';
          break;
        }
        offset += data.items.length;
      }
    }
    final confirmed = <int>{};
    if (error == null) {
      for (final id in ids) {
        if (emit.isDone || isClosed) return;
        final result = await markAsReadUseCase(id);
        if (emit.isDone || isClosed) return;
        switch (result) {
          case Success():
            confirmed.add(id);
          case ResultFailure(:final failure):
            error = failure.message;
        }
      }
    }
    _isMarkingAll = false;
    if (emit.isDone || isClosed) return;
    // Keep confirmed local results even if the following refresh fails.
    _notifications = _notifications
        .map(
          (n) => !confirmed.contains(n.notificationId)
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
                  isWarning: n.isWarning,
                ),
        )
        .where((n) => _filter != 'Unread' || !n.isRead)
        .toList();
    _unreadCount = _unreadCount == null
        ? null
        : (_unreadCount! - confirmed.length).clamp(0, _unreadCount!);
    emit(
      NotificationLoaded(_notifications, _hasMore, unreadCount: _unreadCount),
    );
    await _onLoadNotifications(LoadNotifications(0, _filter), emit);
    final latest = state;
    if (error != null && latest is NotificationLoaded && !emit.isDone) {
      emit(
        latest.copyWith(
          readErrorMessage: error.trim().isEmpty
              ? 'Some notifications could not be marked as read. Please try again.'
              : error,
        ),
      );
    }
  }
}
