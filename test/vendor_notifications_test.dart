import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/auth/domain/enums/role.dart';
import 'package:marikina_market_mobile/features/notification/data/data_sources/notification_remote_data_source.dart';
import 'package:marikina_market_mobile/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:marikina_market_mobile/features/notification/data/models/notification_summary_model.dart';
import 'package:marikina_market_mobile/features/notification/domain/use_cases/load_notifications_use_case.dart';
import 'package:marikina_market_mobile/features/notification/domain/use_cases/load_unread_count_use_case.dart';
import 'package:marikina_market_mobile/features/notification/domain/use_cases/mark_as_read_use_case.dart';
import 'package:marikina_market_mobile/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:marikina_market_mobile/features/notification/presentation/bloc/notification_event.dart';
import 'package:marikina_market_mobile/features/notification/presentation/bloc/notification_state.dart';
import 'features/auth/data/login_mobile_contract_test.dart'
    show contractClient, reply;

const vendorWarning = <String, Object?>{
  'id': 71,
  'vendor_id': 17,
  'enforcer_id': 8,
  'ticket_id': 11,
  'control_number': '11',
  'trade_name': 'Reyes Fresh Fish',
  'market_section_name': 'Fish and Seafood',
  'type': 'Warning',
  'penalty_type': null,
  'total_fine_amount': null,
  'due_date': null,
  'status': null,
  'message': 'Ord. #149 series of 1999 Market Code',
  'is_read': false,
  'created_at': '2026-10-09T02:00:00Z',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'overlapping pages deduplicate cards while advancing the server offset',
    () async {
      final offsets = <int>[];
      final bloc = vendorBloc((options) async {
        if (options.queryParameters['filter'] == 'Unread') {
          return reply(options, {'items': [], 'total': 5, 'has_more': false});
        }
        final offset = options.queryParameters['offset'] as int;
        offsets.add(offset);
        final ids = switch (offset) {
          0 => [71, 72],
          2 => [72, 73],
          _ => [74],
        };
        return reply(options, {
          'items': ids.map((id) => {...vendorWarning, 'id': id}).toList(),
          'has_more': offset < 4,
        });
      });
      Future<void> load(int offset, int length) async {
        final ready = bloc.stream.firstWhere(
          (s) =>
              s is NotificationLoaded &&
              !s.isLoadingMore &&
              s.notifications.length == length,
        );
        bloc.add(LoadNotifications(offset, 'All'));
        await ready;
      }

      await load(0, 2);
      await load(2, 3);
      await load(3, 4);
      expect(offsets, [0, 2, 4]);
      expect(
        (bloc.state as NotificationLoaded).notifications.map(
          (n) => n.notificationId,
        ),
        [71, 72, 73, 74],
      );
    },
  );

  test(
    'bulk snapshot failure performs no writes and exposes a retryable error',
    () async {
      var fail = false;
      var writes = 0;
      final bloc = vendorBloc((options) async {
        if (options.method == 'PATCH') writes++;
        if (fail && options.queryParameters['filter'] == 'Unread') {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          );
        }
        return reply(options, {
          'items': [vendorWarning],
          'total': 1,
          'has_more': false,
        });
      });
      final ready = bloc.stream.firstWhere((s) => s is NotificationLoaded);
      bloc.add(LoadNotifications(0, 'All'));
      await ready;
      fail = true;
      final finished = bloc.stream.firstWhere(
        (s) => s is NotificationLoaded && s.readErrorMessage != null,
      );
      bloc.add(MarkAllAsRead());
      await finished;
      expect(writes, 0);
      final result = bloc.state as NotificationLoaded;
      expect(result.notifications.single.isRead, isFalse);
      expect(result.unreadCount, isNull);
      expect(result.readErrorMessage, contains('No internet connection'));
    },
  );
  test(
    'vendor warning with nullable ticket fields maps without fabricating a status',
    () {
      final warning = NotificationSummaryModel.fromJson(
        vendorWarning,
      ).toEntity();
      expect(warning.status, isNull);
      expect(warning.penaltyType, isNull);
      expect(warning.dueDate, isNull);
      expect(warning.message, 'Ord. #149 series of 1999 Market Code');
    },
  );

  test(
    'vendor list, unread count and read use only the vendor contract',
    () async {
      final requests = <String>[];
      final client = contractClient((options) async {
        requests.add(
          '${options.method} ${options.path} ${options.queryParameters}',
        );
        return reply(options, {
          'items': [vendorWarning],
          'total': 23,
          'has_more': true,
        });
      });
      addTearDown(client.dio.close);
      final source = NotificationRemoteDataSourceImpl(
        client,
        role: Role.marketVendor,
      );
      final page = await source.getNotifications(10, 'All');
      expect(page.items.single.toEntity().isWarning, isTrue);
      expect(await source.getUnreadCount(), 23);
      await source.markAsRead(71);
      expect(requests, [
        'GET /notification/vendor {offset: 10, filter: All}',
        'GET /notification/vendor {offset: 0, filter: Unread}',
        'PATCH /notification/vendor/71/read {}',
      ]);
    },
  );

  test(
    'integer fine amounts map and enforcer endpoints are preserved',
    () async {
      final client = contractClient((options) async {
        expect(
          options.path,
          options.method == 'GET' ? '/notification' : '/notification/71/read',
        );
        return reply(options, {
          'items': [
            {
              ...vendorWarning,
              'type': 'Ticket',
              'penalty_type': 'CashFine',
              'status': 'Pending',
              'total_fine_amount': 500,
            },
          ],
          'has_more': false,
        });
      });
      addTearDown(client.dio.close);
      final source = NotificationRemoteDataSourceImpl(client);
      expect(
        (await source.getNotifications(0, 'All')).items.single.totalFineAmount,
        500.0,
      );
      await source.markAsRead(71);
    },
  );

  test(
    'server denial and malformed responses become domain failures',
    () async {
      var deny = true;
      final client = contractClient((options) async {
        if (deny) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response<Object?>(
              requestOptions: options,
              statusCode: 403,
              data: {'message': 'Vendor access required.'},
            ),
          );
        }
        return reply(options, {
          'items': [
            {'id': 'invalid'},
          ],
          'has_more': false,
        });
      });
      addTearDown(client.dio.close);
      final repo = NotificationRepositoryImpl(
        NotificationRemoteDataSourceImpl(client, role: Role.marketVendor),
      );
      final denied = await repo.loadNotifications(0, 'All');
      expect(denied, isA<ResultFailure>());
      if (denied case ResultFailure(:final failure)) {
        expect(failure.message, 'Vendor access required.');
      }
      deny = false;
      expect(await repo.loadNotifications(0, 'All'), isA<ResultFailure>());
    },
  );

  test(
    'mark all snapshots every unread page before writes and retains partial failures',
    () async {
      final unread = {71, 72, 73};
      final calls = <String>[];
      final bloc = vendorBloc((options) async {
        final filter = options.queryParameters['filter'];
        final offset = options.queryParameters['offset'] as int? ?? 0;
        if (options.method == 'PATCH') {
          final id = int.parse(options.path.split('/')[3]);
          calls.add('read $id');
          if (id == 72) {
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
        calls.add('$filter $offset');
        final ids = filter == 'Unread' ? unread.toList() : [71, 72, 73];
        return reply(options, {
          'items': ids
              .skip(offset)
              .take(2)
              .map(
                (id) => {
                  ...vendorWarning,
                  'id': id,
                  'is_read': !unread.contains(id),
                },
              )
              .toList(),
          'has_more': offset + 2 < ids.length,
          'total': unread.length,
        });
      });
      final ready = bloc.stream.firstWhere(
        (s) => s is NotificationLoaded && !s.isRefreshing,
      );
      bloc.add(LoadNotifications(0, 'All'));
      await ready;
      expect((bloc.state as NotificationLoaded).unreadCount, 3);
      calls.clear();
      final finished = bloc.stream.firstWhere(
        (s) =>
            s is NotificationLoaded &&
            !s.isMarkingAll &&
            s.readErrorMessage != null,
      );
      bloc.add(MarkAllAsRead());
      await finished;
      expect(calls.take(5), [
        'Unread 0',
        'Unread 2',
        'read 71',
        'read 72',
        'read 73',
      ]);
      expect(unread, {72});
      final state = bloc.state as NotificationLoaded;
      expect(state.unreadCount, 1);
      expect(state.notifications.first.isRead, isTrue);
      expect(state.notifications[1].isRead, isFalse);
    },
  );

  test(
    'Unread paging resets after a confirmed read so shifted rows are not skipped',
    () async {
      final unread = [71, 72, 73];
      final offsets = <int>[];
      final bloc = vendorBloc((options) async {
        if (options.method == 'PATCH') {
          unread.remove(71);
          return reply(options, null);
        }
        final offset = options.queryParameters['offset'] as int;
        offsets.add(offset);
        return reply(options, {
          'items': unread
              .skip(offset)
              .take(2)
              .map((id) => {...vendorWarning, 'id': id})
              .toList(),
          'has_more': offset + 2 < unread.length,
          'total': unread.length,
        });
      });
      final ready = bloc.stream.firstWhere(
        (s) => s is NotificationLoaded && !s.isRefreshing,
      );
      bloc.add(LoadNotifications(0, 'Unread'));
      await ready;
      final read = bloc.stream.firstWhere(
        (s) =>
            s is NotificationLoaded &&
            s.notifications.any((n) => n.notificationId == 73),
      );
      bloc.add(MarkAsRead(71));
      await read;
      expect(
        (bloc.state as NotificationLoaded).notifications.map(
          (n) => n.notificationId,
        ),
        [72, 73],
      );
      expect(offsets, everyElement(0));
    },
  );
}

NotificationBloc vendorBloc(
  Future<Response<Object?>> Function(RequestOptions) respond,
) {
  final client = contractClient(respond);
  addTearDown(client.dio.close);
  final repo = NotificationRepositoryImpl(
    NotificationRemoteDataSourceImpl(client, role: Role.marketVendor),
  );
  final bloc = NotificationBloc(
    loadNotificationsUseCase: LoadNotificationsUseCase(repo),
    markAsReadUseCase: MarkAsReadUseCase(repo),
    loadUnreadCountUseCase: LoadUnreadCountUseCase(repo),
  );
  addTearDown(() async {
    if (!bloc.isClosed) await bloc.close();
  });
  return bloc;
}
