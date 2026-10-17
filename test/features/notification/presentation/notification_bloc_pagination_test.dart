import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/page_result.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';
import 'package:marikina_market_mobile/core/utils/unit.dart';
import 'package:marikina_market_mobile/features/notification/domain/entities/notification_list_data.dart';
import 'package:marikina_market_mobile/features/notification/domain/entities/notification_summary.dart';
import 'package:marikina_market_mobile/features/notification/domain/repositories/notification_repository.dart';
import 'package:marikina_market_mobile/features/notification/domain/use_cases/load_notifications_use_case.dart';
import 'package:marikina_market_mobile/features/notification/domain/use_cases/mark_as_read_use_case.dart';
import 'package:marikina_market_mobile/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:marikina_market_mobile/features/notification/presentation/bloc/notification_event.dart';
import 'package:marikina_market_mobile/features/notification/presentation/bloc/notification_state.dart';
import 'package:marikina_market_mobile/features/notification/presentation/widgets/notification_list.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';

void main() {
  test(
    'appends one page at a time and ignores duplicate load-more events',
    () async {
      final repository = _NotificationRepository();
      final bloc = NotificationBloc(
        loadNotificationsUseCase: LoadNotificationsUseCase(repository),
        markAsReadUseCase: MarkAsReadUseCase(repository),
      );
      addTearDown(bloc.close);

      final firstPage = bloc.stream.firstWhere(
        (state) => state is NotificationLoaded && !state.isRefreshing,
      );
      bloc.add(LoadNotifications(0, 'All'));
      await firstPage;

      final lastPage = bloc.stream.firstWhere(
        (state) =>
            state is NotificationLoaded &&
            !state.isLoadingMore &&
            state.notifications.length == 3,
      );
      bloc
        ..add(LoadNotifications(2, 'All'))
        ..add(LoadNotifications(2, 'All'));

      await Future<void>.delayed(Duration.zero);
      expect(repository.requestedOffsets, [0, 2]);
      expect(
        bloc.state,
        isA<NotificationLoaded>().having(
          (state) => state.isLoadingMore,
          'isLoadingMore',
          true,
        ),
      );

      repository.nextPage.complete(
        Success(PageResult(items: [_notification(3)], hasMore: false)),
      );
      await lastPage;

      final loaded = bloc.state as NotificationLoaded;
      expect(loaded.notifications.map((item) => item.notificationId), [
        1,
        2,
        3,
      ]);
      expect(loaded.hasMore, isFalse);
      expect(loaded.isLoadingMore, isFalse);
    },
  );

  test('can refresh when the dataset is empty', () async {
    final repository = _NotificationRepository(
      firstPageItems: const [],
      firstPageHasMore: false,
    );
    final bloc = NotificationBloc(
      loadNotificationsUseCase: LoadNotificationsUseCase(repository),
      markAsReadUseCase: MarkAsReadUseCase(repository),
    );
    addTearDown(bloc.close);

    final loaded = bloc.stream.firstWhere(
      (state) => state is NotificationLoaded,
    );
    bloc.add(LoadNotifications(0, 'All'));
    await loaded;

    expect(repository.requestedOffsets, [0]);
    expect((bloc.state as NotificationLoaded).notifications, isEmpty);

    final refreshed = bloc.stream.firstWhere(
      (state) => state is NotificationLoaded,
    );
    bloc.add(LoadNotifications(0, 'All'));
    await refreshed;
    expect(repository.requestedOffsets, [0, 0]);
  });

  testWidgets('notification list shows pagination footer feedback', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NotificationList(
            data: NotificationListData(
              notifications: [_notification(1)],
              hasMore: false,
              isLoadingMore: false,
              errorMessage: null,
              isLoadMoreError: false,
            ),
            onRead: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('All notifications loaded'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NotificationList(
            data: NotificationListData(
              notifications: [_notification(1)],
              hasMore: true,
              isLoadingMore: true,
              errorMessage: null,
              isLoadMoreError: false,
            ),
            onRead: (_) {},
          ),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}

class _NotificationRepository implements NotificationRepository {
  @override
  Future<Result<int>> loadUnreadCount() async => const Success(0);
  _NotificationRepository({
    this.firstPageItems = const [],
    this.firstPageHasMore = true,
  });

  final List<NotificationSummary> firstPageItems;
  final bool firstPageHasMore;
  final List<int> requestedOffsets = [];
  final Completer<Result<PageResult<NotificationSummary>>> nextPage =
      Completer<Result<PageResult<NotificationSummary>>>();

  @override
  Future<Result<PageResult<NotificationSummary>>> loadNotifications(
    int offset,
    String filter,
  ) async {
    requestedOffsets.add(offset);
    if (offset > 0) return nextPage.future;

    final items = firstPageItems.isEmpty && firstPageHasMore
        ? [_notification(1), _notification(2)]
        : firstPageItems;
    return Success(PageResult(items: items, hasMore: firstPageHasMore));
  }

  @override
  Future<Result<Unit>> markAsRead(int id) async => const Success(unit);
}

NotificationSummary _notification(int id) => NotificationSummary(
  notificationId: id,
  enforcerId: 1,
  ticketId: id,
  controlNumber: 'T-$id',
  tradeName: 'Vendor $id',
  marketSection: 'Section A',
  penaltyType: PenaltyType.cashFine,
  dueDate: DateTime(2026),
  status: TicketStatus.pending,
  message: 'Ticket update',
  isRead: false,
  createdAt: DateTime(2026),
);
