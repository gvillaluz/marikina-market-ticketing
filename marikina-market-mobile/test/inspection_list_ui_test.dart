import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/skeleton_box.dart';
import 'package:marikina_market_mobile/features/tickets/data/data_sources/inspection_local_data_source.dart';
import 'package:marikina_market_mobile/features/tickets/data/data_sources/inspection_remote_data_source.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_hive_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/inspection_summary_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/repositories/inspection_repository_impl.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/load_inspection_list_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/load_ordinances_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/search_vendor_by_code_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/search_vendor_by_stall_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/get_fine_summary_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/check_warning_ordinances_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/save_inspection_ticket_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_event.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_state.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/inspection_card.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/inspection_list_footer.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/filter_row.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/pages/inspections_page.dart';
import 'features/auth/data/login_mobile_contract_test.dart'
    show contractClient, reply;

const inspectionResponse = <String, Object?>{
  'id': 42,
  'type': 'Ticket',
  'control_number': 'TKT-2026-0042',
  'vendor_id': 12,
  'first_name': 'Maria Isabel',
  'last_name': 'Dela Cruz Santos',
  'business_name': 'Market Goods and General Merchandise',
  'market_section_id': 1,
  'market_section_name': 'Section A',
  'enforcer_id': 7,
  'vendor_type': 'Public',
  'business_id': 'BUS-12',
  'stall_number': 'A-12',
  'status': 'Overdue',
  'severity': 'Moderate',
  'ordinance_names': ['Keep the stall and its surroundings clean.'],
  'issued_at': '2026-10-07T08:00:00Z',
  'updated_at': '2026-10-07T08:00:00Z',
  'overdue_date': null,
};

Future<InspectionBloc> listBloc(
  Future<Response<Object?>> Function(RequestOptions) respond,
) async {
  final folder = await Directory.systemTemp.createTemp('inspection-list-test-');
  final box = await Hive.openBox<OrdinanceHiveModel>(
    'ordinances',
    path: folder.path,
  );
  addTearDown(() async {
    await box.close();
    await folder.delete(recursive: true);
  });
  final client = contractClient(respond);
  addTearDown(client.dio.close);
  final repository = InspectionRepositoryImpl(
    InspectionRemoteDataSourceImpl(client),
    InspectionLocalDataSourceImpl(box),
  );
  final bloc = InspectionBloc(
    loadInspectionListUseCase: LoadInspectionListUseCase(repository),
    loadOrdinancesUseCase: LoadOrdinancesUseCase(repository),
    searchVendorByCodeUseCase: SearchVendorByCodeUseCase(repository),
    searchVendorByStallUseCase: SearchVendorByStallUseCase(repository),
    getFineSummaryUseCase: GetFineSummaryUseCase(repository),
    checkWarningOrdinancesUseCase: CheckWarningOrdinancesUseCase(repository),
    saveInspectionTicketUseCase: SaveInspectionTicketUseCase(repository),
  );
  addTearDown(bloc.close);
  return bloc;
}

Future<void> showList(WidgetTester tester, InspectionBloc bloc) =>
    tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: const Scaffold(body: InspectionsPage()),
          ),
        ),
      ),
    );

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  for (final disableAnimations in [true, false]) {
    for (final loadingMore in [true, false]) {
      testWidgets(
        'inspection footer has valid semantics: disableAnimations=$disableAnimations loadingMore=$loadingMore',
        (tester) async {
          final semantics = tester.ensureSemantics();
          try {
            await tester.pumpWidget(
              MaterialApp(
                theme: AppTheme.light,
                home: MediaQuery(
                  data: MediaQueryData(disableAnimations: disableAnimations),
                  child: Scaffold(
                    body: InspectionListFooter(
                      state: InspectionTicketsLoaded(
                        [],
                        true,
                        isRefreshing: !loadingMore,
                        isLoadingMore: loadingMore,
                      ),
                    ),
                  ),
                ),
              ),
            );
            final data = tester
                .getSemantics(find.byType(CircularProgressIndicator))
                .getSemanticsData();
            expect(
              data.label,
              loadingMore
                  ? 'Loading more inspections'
                  : 'Refreshing inspections',
            );
            expect(data.value, disableAnimations ? '75' : '');
            expect(data.minValue, disableAnimations ? '0' : isNull);
            expect(data.maxValue, disableAnimations ? '100' : isNull);
            await tester.pump(const Duration(milliseconds: 100));
            expect(tester.binding.hasScheduledFrame, !disableAnimations);
            expect(tester.takeException(), isNull);
          } finally {
            await tester.pumpWidget(const SizedBox.shrink());
            semantics.dispose();
          }
        },
      );
    }
  }

  testWidgets(
    'inspection card wraps at 280px with large text and missing overdue date',
    (tester) async {
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
                padding: const EdgeInsets.all(20),
                child: InspectionCard(
                  ticketSummary: InspectionSummaryModel.fromJson(
                    inspectionResponse,
                  ).toEntity(),
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Overdue'), findsOneWidget);
      expect(find.textContaining('null'), findsNothing);
    },
  );

  testWidgets(
    'empty inspection results stay visible through refresh and refresh failure',
    (tester) async {
      var calls = 0;
      final started = Completer<RequestOptions>();
      final release = Completer<void>();
      final bloc = await tester.runAsync(
        () => listBloc((options) async {
          if (++calls == 1) {
            return reply(options, {'items': [], 'has_more': false});
          }
          if (!started.isCompleted) started.complete(options);
          await release.future;
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          );
        }),
      );
      addTearDown(() {
        if (!release.isCompleted) release.complete();
      });
      await tester.runAsync(() async {
        final loaded = bloc!.stream.firstWhere(
          (state) => state is InspectionTicketsLoaded,
        );
        bloc.add(LoadInspectionTickets());
        await loaded;
      });
      await showList(tester, bloc!);
      final refresh = tester
          .widget<RefreshIndicator>(find.byType(RefreshIndicator))
          .onRefresh();
      await tester.pump();
      await tester.runAsync(() => pumpEventQueue());
      await tester.pump(const Duration(milliseconds: 20));
      expect(started.isCompleted, isTrue);
      final options = await started.future;
      expect(options.path, '/enforcer/tickets/inspections');
      expect(calls, 2);
      expect((bloc.state as InspectionTicketsLoaded).isRefreshing, isTrue);
      expect(find.text('No inspections found'), findsOneWidget);
      expect(find.byType(SkeletonBox), findsNothing);
      release.complete();
      await tester.pump();
      await tester.runAsync(() => pumpEventQueue());
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pumpAndSettle();
      expect((bloc.state as InspectionTicketsLoaded).isRefreshing, isFalse);
      await refresh;
      expect(calls, 2);
      expect(find.text('No inspections found'), findsOneWidget);
      expect(
        find.text('No internet connection. Please try again.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  test(
    'paging is blocked during refresh and duplicate refreshes share the current request',
    () async {
      var calls = 0;
      final started = Completer<RequestOptions>();
      final pending = Completer<Response<Object?>>();
      final bloc = await listBloc((options) async {
        if (++calls == 1) {
          return reply(options, {
            'items': [inspectionResponse],
            'has_more': true,
          });
        }
        started.complete(options);
        return pending.future;
      });
      final loaded = bloc.stream.firstWhere(
        (state) => state is InspectionTicketsLoaded,
      );
      bloc.add(LoadInspectionTickets());
      await loaded;
      bloc.add(LoadInspectionTickets());
      final options = await started.future;
      bloc.add(LoadInspectionTickets());
      bloc.add(LoadInspectionTickets(offset: 1));
      await Future<void>.delayed(Duration.zero);
      expect(calls, 2);
      expect((bloc.state as InspectionTicketsLoaded).isRefreshing, isTrue);
      expect((bloc.state as InspectionTicketsLoaded).isLoadingMore, isFalse);
      final finished = bloc.stream.firstWhere(
        (state) => state is InspectionTicketsLoaded && !state.isRefreshing,
      );
      pending.complete(
        reply(options, {
          'items': [inspectionResponse],
          'has_more': true,
        }),
      );
      await finished;
    },
  );

  testWidgets('changing filter cancels pending search debounce', (
    tester,
  ) async {
    final requests = <RequestOptions>[];
    final bloc = await tester.runAsync(
      () => listBloc((options) async {
        requests.add(options);
        return reply(options, {'items': [], 'has_more': false});
      }),
    );
    try {
      await showList(tester, bloc!);
      final filters = find.byType(FilterRow);
      for (final label in ['All', 'Warnings', 'Tickets']) {
        expect(
          find.descendant(
            of: filters,
            matching: find.widgetWithText(TextButton, label),
          ),
          findsOneWidget,
        );
      }
      expect(tester.widget<FilterRow>(filters).typeSelected, isNull);
      await tester.enterText(find.byType(TextField), 'Market');
      await tester.pump(const Duration(milliseconds: 100));
      expect(requests, isEmpty);
      await tester.tap(
        find.descendant(
          of: filters,
          matching: find.widgetWithText(TextButton, 'Tickets'),
        ),
      );
      await tester.pump();
      await tester.runAsync(() => pumpEventQueue());
      await tester.pump(const Duration(milliseconds: 20));
      expect(requests, hasLength(1));
      expect(requests.single.method, 'GET');
      expect(requests.single.path, '/enforcer/tickets/inspections');
      expect(requests.single.queryParameters, {
        'search': 'Market',
        'offset': 0,
        'type': 'Ticket',
      });
      expect(bloc.state, isA<InspectionTicketsLoaded>());
      expect((bloc.state as InspectionTicketsLoaded).isRefreshing, isFalse);
      expect(
        tester.widget<FilterRow>(filters).typeSelected,
        ViolationType.ticket,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Market',
      );
      // Finish the filter request before the old search timer would fire, so a
      // duplicate request cannot be hidden by the BLoC's in-flight guard.
      await tester.pump(const Duration(milliseconds: 450));
      await tester.runAsync(() => pumpEventQueue());
      await tester.pumpAndSettle();
      expect(requests, hasLength(1));
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
