import 'dart:io';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:marikina_market_mobile/core/di/dependency_injection.dart' as di;
import 'package:marikina_market_mobile/core/network/client.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_hive_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/features/notification/data/data_sources/notification_remote_data_source.dart';
import 'package:marikina_market_mobile/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:marikina_market_mobile/features/notification/domain/use_cases/load_notifications_use_case.dart';
import 'package:marikina_market_mobile/features/notification/domain/use_cases/load_unread_count_use_case.dart';
import 'package:marikina_market_mobile/features/notification/domain/use_cases/mark_as_read_use_case.dart';
import 'package:marikina_market_mobile/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:marikina_market_mobile/features/notification/presentation/bloc/notification_event.dart';
import 'package:marikina_market_mobile/features/notification/presentation/bloc/notification_state.dart';
import 'features/auth/data/login_mobile_contract_test.dart'
    show contractClient, reply;

const enforcerNotice = <String, Object?>{
  'id': 71,
  'enforcer_id': 8,
  'ticket_id': 42,
  'control_number': 'TKT-2026-0042',
  'trade_name': 'Reyes Fresh Fish',
  'market_section_name': 'Fish and Seafood',
  'penalty_type': 'CashFine',
  'total_fine_amount': 1500,
  'due_date': '2026-10-26T02:00:00Z',
  'status': 'Paid',
  'message': 'Ticket TKT-2026-0042 for Reyes Fresh Fish is now Paid.',
  'is_read': false,
  'created_at': '2026-10-21T02:00:00Z',
};

NotificationBloc enforcerBloc(
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
    loadUnreadCountUseCase: LoadUnreadCountUseCase(repository),
  );
  addTearDown(() async {
    if (!bloc.isClosed) await bloc.close();
  });
  return bloc;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'production enforcer DI loads unread count through the enforcer route',
    () async {
      final folder = await Directory.systemTemp.createTemp('slice4-di-');
      final box = await Hive.openBox<OrdinanceHiveModel>(
        'ordinances',
        path: folder.path,
      );
      await di.sl.reset();
      addTearDown(() async {
        await di.sl.reset();
        await box.deleteFromDisk();
        await folder.delete();
      });
      await di.init(box);
      final requests = <String>[];
      final client = contractClient((options) async {
        requests.add('${options.path} ${options.queryParameters['filter']}');
        return reply(options, {
          'items': [enforcerNotice],
          'total': 12,
          'has_more': true,
        });
      });
      addTearDown(client.dio.close);
      await di.sl.unregister<ApiClient>();
      di.sl.registerSingleton<ApiClient>(client);
      final bloc = di.sl<NotificationBloc>();
      addTearDown(bloc.close);
      final loaded = bloc.stream.firstWhere((s) => s is NotificationLoaded);
      bloc.add(LoadNotifications(0, 'All'));
      await loaded;
      expect((bloc.state as NotificationLoaded).unreadCount, 12);
      expect(requests, ['/notification All', '/notification Unread']);
    },
  );

  for (final partialFailure in [false, true]) {
    test(
      'enforcer snapshots 12 unread IDs before writes; partial failure $partialFailure and retry',
      () async {
        final unread = {for (var id = 71; id <= 82; id++) id};
        final calls = <String>[];
        var fail = partialFailure;
        final bloc = enforcerBloc((options) async {
          expect(options.path, startsWith('/notification'));
          expect(options.path, isNot(contains('/vendor')));
          if (options.method == 'PATCH') {
            final id = int.parse(options.path.split('/')[2]);
            calls.add('read $id');
            if (fail && id == 72) {
              throw DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response<Object?>(
                  requestOptions: options,
                  statusCode: 500,
                  data: {'message': 'Please retry this item.'},
                ),
              );
            }
            unread.remove(id);
            return reply(options, null);
          }
          final filter = options.queryParameters['filter'];
          final offset = options.queryParameters['offset'] as int;
          calls.add('$filter $offset');
          final ids = filter == 'Unread'
              ? unread.toList()
              : [for (var id = 71; id <= 82; id++) id];
          return reply(options, {
            'items': ids
                .skip(offset)
                .take(10)
                .map(
                  (id) => {
                    ...enforcerNotice,
                    'id': id,
                    'is_read': !unread.contains(id),
                  },
                )
                .toList(),
            'has_more': offset + 10 < ids.length,
            'total': ids.length,
          });
        });
        var ready = bloc.stream.firstWhere(
          (s) => s is NotificationLoaded && !s.isRefreshing,
        );
        bloc.add(LoadNotifications(0, 'All'));
        await ready;
        expect((bloc.state as NotificationLoaded).unreadCount, 12);
        calls.clear();
        final finished = bloc.stream.firstWhere(
          (s) =>
              s is NotificationLoaded &&
              (partialFailure
                  ? s.readErrorMessage != null
                  : s.unreadCount == 0 && !s.isRefreshing),
        );
        bloc.add(MarkAllAsRead());
        bloc.add(MarkAllAsRead());
        await finished;
        expect(calls.take(14), [
          'Unread 0',
          'Unread 10',
          for (var id = 71; id <= 82; id++) 'read $id',
        ]);
        expect(calls.where((c) => c.startsWith('read ')).length, 12);
        final state = bloc.state as NotificationLoaded;
        expect(state.unreadCount, partialFailure ? 1 : 0);
        expect(unread, partialFailure ? {72} : isEmpty);
        expect(state.notifications.first.isRead, isTrue);
        if (partialFailure) {
          expect(state.notifications[1].isRead, isFalse);
          expect(state.readErrorMessage, 'Please retry this item.');
          fail = false;
          calls.clear();
          ready = bloc.stream.firstWhere(
            (s) =>
                s is NotificationLoaded &&
                s.unreadCount == 0 &&
                !s.isRefreshing,
          );
          bloc.add(MarkAllAsRead());
          await ready;
          expect(calls.where((c) => c.startsWith('read ')), ['read 72']);
          expect(unread, isEmpty);
        }
      },
    );
  }

  test(
    'enforcer pagination appends the second page without duplicate rows',
    () async {
      final offsets = <int>[];
      final bloc = enforcerBloc((options) async {
        final offset = options.queryParameters['offset'] as int;
        if (options.queryParameters['filter'] == 'All') offsets.add(offset);
        return reply(options, {
          'items': [
            for (var id = 71; id <= 82; id++) {...enforcerNotice, 'id': id},
          ].skip(offset).take(10).toList(),
          'total': 12,
          'has_more': offset == 0,
        });
      });
      var loaded = bloc.stream.firstWhere((s) => s is NotificationLoaded);
      bloc.add(LoadNotifications(0, 'All'));
      await loaded;
      expect((bloc.state as NotificationLoaded).notifications.length, 10);
      loaded = bloc.stream.firstWhere(
        (s) =>
            s is NotificationLoaded &&
            !s.isLoadingMore &&
            s.notifications.length == 12,
      );
      bloc.add(LoadNotifications(10, 'All'));
      await loaded;
      expect(offsets, [0, 10]);
      final state = bloc.state as NotificationLoaded;
      expect(state.notifications.map((n) => n.notificationId), [
        for (var id = 71; id <= 82; id++) id,
      ]);
      expect(state.hasMore, isFalse);
      expect(state.unreadCount, 12);
    },
  );

  test(
    'enforcer snapshot failure performs no writes and preserves unread rows',
    () async {
      var fail = false;
      var writes = 0;
      final bloc = enforcerBloc((options) async {
        if (options.method == 'PATCH') writes++;
        if (fail && options.queryParameters['filter'] == 'Unread') {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          );
        }
        return reply(options, {
          'items': [enforcerNotice],
          'has_more': false,
          'total': 1,
        });
      });
      final loaded = bloc.stream.firstWhere((s) => s is NotificationLoaded);
      bloc.add(LoadNotifications(0, 'All'));
      await loaded;
      fail = true;
      final failed = bloc.stream.firstWhere(
        (s) => s is NotificationLoaded && s.readErrorMessage != null,
      );
      bloc.add(MarkAllAsRead());
      await failed;
      expect(writes, 0);
      final state = bloc.state as NotificationLoaded;
      expect(state.notifications.single.isRead, isFalse);
      expect(state.unreadCount, isNull);
      expect(state.readErrorMessage, contains('No internet connection'));
    },
  );

  test('enforcer unread count contract rejects unavailable totals', () async {
    final client = contractClient((options) async {
      expect(options.path, '/notification');
      expect(options.queryParameters, {'offset': 0, 'filter': 'Unread'});
      return reply(options, {'items': [], 'has_more': false, 'total': null});
    });
    addTearDown(client.dio.close);
    expect(
      NotificationRemoteDataSourceImpl(client).getUnreadCount(),
      throwsFormatException,
    );
  });
}
