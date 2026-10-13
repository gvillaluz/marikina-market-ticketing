import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/notification/data/data_sources/notification_remote_data_source.dart';
import 'package:marikina_market_mobile/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:marikina_market_mobile/features/notification/data/models/notification_summary_model.dart';
import 'package:marikina_market_mobile/features/notification/domain/entities/notification_list_data.dart';
import 'package:marikina_market_mobile/features/notification/domain/use_cases/load_notifications_use_case.dart';
import 'package:marikina_market_mobile/features/notification/domain/use_cases/mark_as_read_use_case.dart';
import 'package:marikina_market_mobile/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:marikina_market_mobile/features/notification/presentation/bloc/notification_event.dart';
import 'package:marikina_market_mobile/features/notification/presentation/bloc/notification_state.dart';
import 'package:marikina_market_mobile/features/notification/presentation/widgets/notification_list.dart';
import 'package:marikina_market_mobile/features/notification/presentation/widgets/notification_tile.dart';
import 'package:marikina_market_mobile/features/notification/presentation/widgets/filters.dart';
import 'features/auth/data/login_mobile_contract_test.dart'
    show contractClient, reply;

const notificationResponse = <String, Object?>{
  'id': 1,
  'enforcer_id': 7,
  'ticket_id': 42,
  'control_number': 'TKT-2026-0042',
  'trade_name': 'Market Goods and General Merchandise',
  'market_section_name': 'Section A',
  'penalty_type': 'CashFine',
  'total_fine_amount': 1500.0,
  'due_date': '2026-10-22T08:00:00Z',
  'status': 'Pending',
  'message': 'Your ticket has been updated.',
  'is_read': false,
  'created_at': '2026-10-07T08:00:00Z',
};
NotificationBloc notificationBloc(
  Future<Response<Object?>> Function(RequestOptions) respond,
) {
  final client = contractClient(respond);
  addTearDown(client.dio.close);
  final repository = NotificationRepositoryImpl(
    NotificationRemoteDataSourceImpl(client),
  );
  final bloc = NotificationBloc(
    loadNotificationsUseCase: LoadNotificationsUseCase(repository),
    markAsReadUseCase: MarkAsReadUseCase(repository),
  );
  addTearDown(bloc.close);
  return bloc;
}

void main() {
  test(
    'confirmed read removes only that notification from the Unread filter',
    () async {
      final bloc = notificationBloc(
        (options) async => options.method == 'GET'
            ? reply(options, {
                'items': [
                  notificationResponse,
                  {...notificationResponse, 'id': 2},
                ],
                'has_more': false,
              })
            : reply(options, {}),
      );
      final loaded = bloc.stream.firstWhere(
        (state) => state is NotificationLoaded,
      );
      bloc.add(LoadNotifications(0, 'Unread'));
      await loaded;
      final read = bloc.stream.firstWhere(
        (state) =>
            state is NotificationLoaded &&
            state.notifications.length == 1 &&
            state.markingReadIds.isEmpty,
      );
      bloc.add(MarkAsRead(1));
      await read;
      expect(
        (bloc.state as NotificationLoaded).notifications.single.notificationId,
        2,
      );
      expect(
        (bloc.state as NotificationLoaded).notifications.single.isRead,
        isFalse,
      );
    },
  );
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  testWidgets('notification tiles and filters fit 280px with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(280, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  Filters(filterOption: 'All', onChange: (_) {}),
                  NotificationTile(
                    notification: NotificationSummaryModel.fromJson(
                      notificationResponse,
                    ).toEntity(),
                    onRead: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('notification list builds visible tiles lazily', (tester) async {
    final data = NotificationListData(
      notifications: List.generate(
        100,
        (index) => NotificationSummaryModel.fromJson({
          ...notificationResponse,
          'id': index + 1,
        }).toEntity(),
      ),
      hasMore: false,
      isLoadingMore: false,
      errorMessage: null,
      isLoadMoreError: false,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: NotificationList(data: data, onRead: (_) {}),
        ),
      ),
    );
    expect(find.byType(NotificationTile).evaluate().length, lessThan(20));
    expect(tester.takeException(), isNull);
  });
  testWidgets('same day number in another month is grouped Earlier', (
    tester,
  ) async {
    final now = DateTime.now();
    final previousMonth = DateTime(
      now.year,
      now.month - 1,
      now.day.clamp(1, 28),
    );
    final data = NotificationListData(
      notifications: [
        NotificationSummaryModel.fromJson({
          ...notificationResponse,
          'created_at': DateTime(
            now.year - 1,
            now.month,
            now.day,
          ).toIso8601String(),
        }).toEntity(),
        NotificationSummaryModel.fromJson({
          ...notificationResponse,
          'id': 2,
          'created_at': previousMonth.toIso8601String(),
        }).toEntity(),
      ],
      hasMore: false,
      isLoadingMore: false,
      errorMessage: null,
      isLoadMoreError: false,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: NotificationList(data: data, onRead: (_) {}),
        ),
      ),
    );
    expect(find.text('Today'), findsNothing);
    expect(find.text('Earlier'), findsOneWidget);
  });
  test(
    'read failures keep item unread, and duplicate reads share one request',
    () async {
      var readCalls = 0;
      final started = Completer<RequestOptions>();
      final pending = Completer<Response<Object?>>();
      final bloc = notificationBloc((options) async {
        if (options.method == 'GET') {
          return reply(options, {
            'items': [notificationResponse],
            'has_more': false,
          });
        }
        readCalls++;
        started.complete(options);
        return pending.future;
      });
      final loaded = bloc.stream.firstWhere(
        (state) => state is NotificationLoaded,
      );
      bloc.add(LoadNotifications(0, 'All'));
      await loaded;
      bloc.add(MarkAsRead(1));
      final options = await started.future;
      bloc.add(MarkAsRead(1));
      await Future<void>.delayed(Duration.zero);
      expect(readCalls, 1);
      expect(
        (bloc.state as NotificationLoaded).notifications.single.isRead,
        isFalse,
      );
      final failed = bloc.stream.firstWhere(
        (state) =>
            state is NotificationLoaded && state.readErrorMessage != null,
      );
      pending.completeError(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      );
      await failed;
      expect(
        (bloc.state as NotificationLoaded).notifications.single.isRead,
        isFalse,
      );
    },
  );
  test(
    'empty refresh stays loaded and blocks pagination while pending',
    () async {
      var calls = 0;
      final started = Completer<RequestOptions>();
      final pending = Completer<Response<Object?>>();
      final bloc = notificationBloc((options) async {
        if (++calls == 1) {
          return reply(options, {'items': [], 'has_more': false});
        }
        started.complete(options);
        return pending.future;
      });
      final loaded = bloc.stream.firstWhere(
        (state) => state is NotificationLoaded,
      );
      bloc.add(LoadNotifications(0, 'All'));
      await loaded;
      final refresh = bloc.refreshNotifications('All');
      final options = await started.future;
      bloc.add(LoadNotifications(0, 'All'));
      bloc.add(LoadNotifications(1, 'All'));
      await Future<void>.delayed(Duration.zero);
      expect(calls, 2);
      expect(bloc.state, isA<NotificationLoaded>());
      pending.completeError(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      );
      await refresh;
      expect((bloc.state as NotificationLoaded).errorMessage, isNotNull);
    },
  );
}
