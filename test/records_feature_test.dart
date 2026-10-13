import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/di/dependency_injection.dart';
import 'package:marikina_market_mobile/core/router/app_routes.dart';
import 'package:marikina_market_mobile/features/records/domain/use_cases/load_record_detail_use_case.dart';
import 'package:marikina_market_mobile/features/records/domain/use_cases/load_vendor_receipt_use_case.dart';
import 'package:marikina_market_mobile/features/records/domain/use_cases/load_vendor_service_progress_use_case.dart';
import 'package:marikina_market_mobile/features/records/domain/use_cases/submit_vendor_receipt_use_case.dart';
import 'package:marikina_market_mobile/features/records/presentation/bloc/vendor_settlement/vendor_settlement_bloc.dart';
import 'package:marikina_market_mobile/features/records/presentation/bloc/record_detail/record_detail_bloc.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/errors/failure.dart';
import 'package:marikina_market_mobile/core/router/mobile_route_access.dart';
import 'package:marikina_market_mobile/features/records/data/data_sources/records_remote_data_source.dart';
import 'package:marikina_market_mobile/features/records/data/repositories/records_repository_impl.dart';
import 'package:marikina_market_mobile/features/records/domain/enums/records_filter.dart';
import 'package:marikina_market_mobile/features/records/domain/entities/records_page_data.dart';
import 'package:marikina_market_mobile/features/records/domain/entities/vendor_ticket_detail.dart';
import 'package:marikina_market_mobile/features/records/domain/use_cases/load_records_use_case.dart';
import 'package:marikina_market_mobile/features/records/presentation/bloc/records/records_bloc.dart';
import 'package:marikina_market_mobile/features/records/presentation/bloc/records/load_records.dart';
import 'package:marikina_market_mobile/features/records/presentation/pages/records_page.dart';
import 'package:marikina_market_mobile/features/records/presentation/widgets/record_card.dart';
import 'package:marikina_market_mobile/features/records/presentation/widgets/vendor_record_detail_content.dart';
import 'features/auth/data/login_mobile_contract_test.dart'
    show contractClient, reply;
import 'mobile_role_access_test.dart' show account;

const recordResponse = <String, Object?>{
  'ticket_id': 101,
  'control_number': '101',
  'type': 'Ticket',
  'violations': ['Market Identification Card'],
  'issued_at': '2026-10-13T00:01:00Z',
  'overdue_date': '2026-10-18T00:01:00Z',
  'ticket_status': 'Pending',
};
const detailResponse = <String, Object?>{
  'ticket_id': 101,
  'enforcer_id': 12,
  'vendor_id': 70,
  'control_number': '101',
  'type': 'Ticket',
  'vendor_type': 'Public',
  'business_id': '2026-0001842',
  'stall_number': 'F-014',
  'business_name': 'Reyes Fresh Seafood',
  'last_name': 'Reyes',
  'first_name': 'Juan',
  'address': '',
  'violations': [
    {
      'ticket_violation_id': 201,
      'ticket_id': 101,
      'ordinance_id': 2,
      'ordinance_no': '104',
      'ordinance_code': 'SAMPLE-002',
      'offense_count': 1,
      'penalty_amount': 500,
    },
  ],
  'issued_at': '2026-10-13T00:01:00Z',
  'market_section_name': 'Fish and Seafood Section',
  'categories': ['Licensing'],
  'description': 'Vendor failed to display a valid market identification card.',
  'severity': 'Minor',
  'penalty_type': 'CashFine',
  'status': 'Pending',
  'due_date': '2026-10-18T00:01:00Z',
  'total_fine_amount': 500,
  'ticket_evidences': <String>[],
};

RecordsRepositoryImpl recordsRepository(
  Future<Response<Object?>> Function(RequestOptions) respond,
) {
  final client = contractClient(respond);
  addTearDown(client.dio.close);
  return RecordsRepositoryImpl(RecordsRemoteDataSource(client));
}

Future<void> fetch(RecordsBloc bloc, LoadRecords event) async {
  final done = bloc.stream.firstWhere(
    (state) =>
        !state.isInitialLoading && !state.isRefreshing && !state.isLoadingMore,
  );
  bloc.add(event);
  await done;
}

void main() {
  testWidgets(
    'scrolling fetches only at the bottom and stops after the last page',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'vendor-test-token',
      });
      final offsets = <int>[];
      final repository = recordsRepository((options) async {
        final offset = options.queryParameters['offset'] as int;
        offsets.add(offset);
        return reply(options, {
          'items': offset == 0
              ? List.generate(
                  10,
                  (index) => {...recordResponse, 'ticket_id': 101 + index},
                )
              : [
                  {...recordResponse, 'ticket_id': 111},
                ],
          'has_more': offset == 0,
          'total': 11,
        });
      });
      final bloc = RecordsBloc(LoadRecordsUseCase(repository));
      addTearDown(bloc.close);
      await tester.runAsync(() => fetch(bloc, const LoadRecords()));
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(body: RecordsPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final controller = tester
          .widget<CustomScrollView>(find.byType(CustomScrollView))
          .controller!;
      controller.jumpTo(controller.position.maxScrollExtent / 2);
      await tester.pumpAndSettle();
      expect(offsets, [0]);
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(offsets, [0, 10]);
      expect(bloc.state.items, hasLength(11));
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(offsets, [0, 10]);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('initial failure retries to an empty always-refreshable list', (
    tester,
  ) async {
    var calls = 0;
    final repository = recordsRepository((options) async {
      if (++calls == 1) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response<Object?>(
            requestOptions: options,
            statusCode: 500,
            data: {'message': 'Unavailable right now.'},
          ),
        );
      }
      return reply(options, {'items': [], 'has_more': false, 'total': 0});
    });
    final bloc = RecordsBloc(LoadRecordsUseCase(repository));
    addTearDown(bloc.close);
    await tester.runAsync(() => fetch(bloc, const LoadRecords()));
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: RecordsPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Unavailable right now.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('No records found.'), findsOneWidget);
    expect(find.text('0 records'), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'View Details uses the vendor endpoint and Back preserves the Records list',
    (tester) async {
      final paths = <String>[];
      final repository = recordsRepository((options) async {
        paths.add(options.path);
        if (options.path.endsWith('/settlement/receipt')) {
          return reply(options, {
            'ticket_id': 101,
            'penalty_type': 'CashFine',
            'proof_urls': [],
          });
        }
        return reply(
          options,
          options.path.endsWith('/inspections')
              ? {
                  'items': [recordResponse],
                  'has_more': false,
                  'total': 1,
                }
              : detailResponse,
        );
      });
      sl.registerFactory<RecordsBloc>(
        () => RecordsBloc(LoadRecordsUseCase(repository)),
      );
      sl.registerFactory<RecordDetailBloc>(
        () => RecordDetailBloc(LoadRecordDetailUseCase(repository)),
      );
      sl.registerFactory<VendorSettlementBloc>(
        () => VendorSettlementBloc(
          loadReceipt: LoadVendorReceiptUseCase(repository),
          loadProgress: LoadVendorServiceProgressUseCase(repository),
          submitReceipt: SubmitVendorReceiptUseCase(repository),
        ),
      );
      addTearDown(() => sl.unregister<VendorSettlementBloc>());
      addTearDown(() => sl.unregister<RecordsBloc>());
      addTearDown(() => sl.unregister<RecordDetailBloc>());
      final router = GoRouter(
        initialLocation: '/vendor/records',
        routes: buildAppRoutes(),
        redirect: (context, state) =>
            MobileRouteAccess.redirect(account('MarketVendor'), state.uri.path),
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('View Details ›'));
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        '/vendor/records/101',
      );
      expect(find.text('Reyes Fresh Seafood'), findsOneWidget);
      expect(paths, [
        '/vendor/tickets/inspections',
        '/vendor/tickets/101',
        '/vendor/tickets/101/settlement/receipt',
      ]);
      await tester.tap(find.byTooltip('Back to records'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/vendor/records');
      expect(find.text('My Records'), findsOneWidget);
      expect(paths, hasLength(3));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  setUp(
    () => FlutterSecureStorage.setMockInitialValues({
      'access_token': 'vendor-test-token',
    }),
  );
  test(
    'all records omit type, encode search, and retain total and due date',
    () async {
      final repository = recordsRepository((options) async {
        expect(options.path, '/vendor/tickets/inspections');
        expect(options.queryParameters, {
          'offset': 0,
          'search': 'market & attire',
        });
        expect(options.headers['Authorization'], 'Bearer vendor-test-token');
        return reply(options, {
          'items': [recordResponse],
          'has_more': true,
          'total': 12,
        });
      });
      final result = await repository.loadRecords(
        search: 'market & attire',
        offset: 0,
        filter: RecordsFilter.all,
      );
      final page = (result as Success<RecordsPageData>).data;
      expect(page.total, 12);
      expect(page.items.single.overdueDate, DateTime.utc(2026, 10, 18, 0, 1));
    },
  );
  test(
    'warning filter preserves nullable warning fields and validates input before HTTP',
    () async {
      var calls = 0;
      final repository = recordsRepository((options) async {
        calls++;
        expect(options.queryParameters, {'offset': 0, 'type': 'Warning'});
        return reply(options, {
          'items': [
            {
              ...recordResponse,
              'type': 'Warning',
              'control_number': null,
              'ticket_status': null,
              'overdue_date': null,
            },
          ],
          'has_more': false,
          'total': 1,
        });
      });
      final result = await repository.loadRecords(
        search: '',
        offset: 0,
        filter: RecordsFilter.warning,
      );
      final warning = (result as Success<RecordsPageData>).data.items.single;
      expect(warning.controlNumber, isNull);
      expect(warning.status, isNull);
      expect(warning.overdueDate, isNull);
      expect(
        await repository.loadRecords(
          search: 'x' * 201,
          offset: 0,
          filter: RecordsFilter.all,
        ),
        isA<ResultFailure<RecordsPageData>>(),
      );
      expect(
        await repository.loadRecords(
          search: '',
          offset: -1,
          filter: RecordsFilter.all,
        ),
        isA<ResultFailure<RecordsPageData>>(),
      );
      expect(calls, 1);
    },
  );
  test(
    'pagination coalesces bottom requests, stops at hasMore false, and retains data on refresh failure',
    () async {
      final started = Completer<RequestOptions>();
      final pending = Completer<Response<Object?>>();
      var calls = 0;
      final repository = recordsRepository((options) async {
        calls++;
        if (calls == 1) {
          return reply(options, {
            'items': [recordResponse],
            'has_more': true,
            'total': 2,
          });
        }
        if (calls == 2) {
          started.complete(options);
          return pending.future;
        }
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      });
      final bloc = RecordsBloc(LoadRecordsUseCase(repository));
      addTearDown(bloc.close);
      await fetch(bloc, const LoadRecords());
      final done = fetch(bloc, const LoadRecords(offset: 1));
      final options = await started.future;
      bloc.add(const LoadRecords(offset: 1));
      await Future<void>.delayed(Duration.zero);
      expect(calls, 2);
      expect(options.queryParameters['offset'], 1);
      pending.complete(
        reply(options, {
          'items': [
            {...recordResponse, 'ticket_id': 102},
          ],
          'has_more': false,
          'total': 2,
        }),
      );
      await done;
      expect(bloc.state.items.map((item) => item.ticketId), [101, 102]);
      bloc.add(const LoadRecords(offset: 2));
      await Future<void>.delayed(Duration.zero);
      expect(calls, 2);
      await bloc.refreshRecords('', RecordsFilter.all);
      expect(bloc.state.items, hasLength(2));
      expect(bloc.state.error, isNotNull);
      expect(bloc.state.isRefreshing, isFalse);
    },
  );
  test(
    'late results from an older filter cannot replace the latest query',
    () async {
      final oldStarted = Completer<RequestOptions>();
      final oldPending = Completer<Response<Object?>>();
      final repository = recordsRepository((options) async {
        if (options.queryParameters['type'] == null) {
          oldStarted.complete(options);
          return oldPending.future;
        }
        return reply(options, {'items': [], 'has_more': false, 'total': 0});
      });
      final bloc = RecordsBloc(LoadRecordsUseCase(repository));
      addTearDown(bloc.close);
      bloc.add(const LoadRecords());
      final oldOptions = await oldStarted.future;
      await fetch(bloc, const LoadRecords(filter: RecordsFilter.warning));
      oldPending.complete(
        reply(oldOptions, {
          'items': [recordResponse],
          'has_more': false,
          'total': 1,
        }),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.filter, RecordsFilter.warning);
      expect(bloc.state.items, isEmpty);
    },
  );
  test(
    'vendor detail uses its own endpoint and maps status, due date, and integer fines',
    () async {
      final repository = recordsRepository((options) async {
        expect(options.path, '/vendor/tickets/101');
        expect(options.queryParameters, isEmpty);
        return reply(options, detailResponse);
      });
      final detail =
          ((await repository.loadDetail(101)) as Success<VendorTicketDetail>)
              .data;
      expect(detail.status!.value, 'Pending');
      expect(detail.dueDate, DateTime.utc(2026, 10, 18, 0, 1));
      expect(detail.totalFine, 500.0);
      expect(detail.violations.single.penaltyAmount, 500.0);
      expect(
        MobileRouteAccess.redirect(
          account('MarketVendor'),
          '/vendor/records/101',
        ),
        isNull,
      );
      expect(
        MobileRouteAccess.redirect(
          account('MarketEnforcer'),
          '/vendor/records/101',
        ),
        '/dashboard',
      );
    },
  );
  test(
    'warning details retain null penalties and signed evidence links',
    () async {
      final repository = recordsRepository(
        (options) async => reply(options, {
          ...detailResponse,
          'type': 'Warning',
          'control_number': null,
          'penalty_type': null,
          'status': null,
          'due_date': null,
          'total_fine_amount': null,
          'ticket_evidences': [
            'https://example.com/signed-evidence-url?signature=sample',
            'file:///private',
            'javascript:alert(1)',
          ],
        }),
      );
      final detail =
          ((await repository.loadDetail(101)) as Success<VendorTicketDetail>)
              .data;
      expect(detail.type, RecordsFilter.warning);
      expect(detail.controlNumber, isNull);
      expect(detail.status, isNull);
      expect(detail.dueDate, isNull);
      expect(detail.totalFine, isNull);
      expect(detail.evidenceUrls, [
        'https://example.com/signed-evidence-url?signature=sample',
      ]);
    },
  );
  test(
    'a failed page keeps existing rows and retries the same offset',
    () async {
      final offsets = <int>[];
      final repository = recordsRepository((options) async {
        final offset = options.queryParameters['offset'] as int;
        offsets.add(offset);
        if (offsets.length == 2) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          );
        }
        return reply(options, {
          'items': [
            {...recordResponse, 'ticket_id': offset == 0 ? 101 : 102},
          ],
          'has_more': offset == 0,
          'total': 2,
        });
      });
      final bloc = RecordsBloc(LoadRecordsUseCase(repository));
      addTearDown(bloc.close);
      await fetch(bloc, const LoadRecords());
      await fetch(bloc, const LoadRecords(offset: 1));
      expect(bloc.state.items, hasLength(1));
      expect(bloc.state.isLoadMoreError, isTrue);
      expect(bloc.state.hasMore, isTrue);
      await fetch(bloc, const LoadRecords(offset: 1));
      expect(offsets, [0, 1, 1]);
      expect(bloc.state.items.map((item) => item.ticketId), [101, 102]);
      expect(bloc.state.error, isNull);
    },
  );
  test(
    'server messages and malformed responses become domain failures',
    () async {
      final repository = recordsRepository((options) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response<Object?>(
            requestOptions: options,
            statusCode: 404,
            data: {'message': 'Ticket not found.'},
          ),
        );
      });
      final result = await repository.loadDetail(101);
      expect(
        (result as ResultFailure<VendorTicketDetail>).failure.message,
        'Ticket not found.',
      );
      final malformed = recordsRepository(
        (options) async =>
            reply(options, {'items': 'bad', 'has_more': false, 'total': 2}),
      );
      expect(
        await malformed.loadRecords(
          search: '',
          offset: 0,
          filter: RecordsFilter.all,
        ),
        isA<ResultFailure<RecordsPageData>>(),
      );
      final denied = recordsRepository(
        (options) async => throw DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response<Object?>(requestOptions: options, statusCode: 403),
        ),
      );
      expect(
        ((await denied.loadDetail(101)) as ResultFailure<VendorTicketDetail>)
            .failure,
        isA<UnauthorizedFailure>(),
      );
    },
  );
  testWidgets(
    'records list and read-only detail fit narrow large-text screens',
    (tester) async {
      tester.view.physicalSize = const Size(280, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = recordsRepository(
        (options) async => reply(
          options,
          options.path.endsWith('/inspections')
              ? {
                  'items': [recordResponse],
                  'has_more': false,
                  'total': 1,
                }
              : detailResponse,
        ),
      );
      final bloc = RecordsBloc(LoadRecordsUseCase(repository));
      addTearDown(bloc.close);
      await tester.runAsync(() => fetch(bloc, const LoadRecords()));
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: MaterialApp(
            theme: AppTheme.light,
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(280, 640),
                textScaler: TextScaler.linear(2),
                disableAnimations: true,
              ),
              child: const Scaffold(body: RecordsPage()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('My Records'), findsOneWidget);
      expect(find.byType(RecordCard), findsOneWidget);
      expect(find.text('1 record'), findsOneWidget);
      expect(find.byType(RefreshIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);
      final detail = await tester.runAsync(() => repository.loadDetail(101));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: VendorRecordDetailContent(
                  detail: (detail! as Success<VendorTicketDetail>).data,
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Reyes Fresh Seafood'), findsOneWidget);
      expect(find.text('Submit receipt'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
