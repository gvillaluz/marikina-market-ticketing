import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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
import 'package:marikina_market_mobile/features/records/presentation/bloc/vendor_settlement/vendor_settlement_bloc.dart';
import 'package:marikina_market_mobile/features/records/presentation/bloc/record_detail/record_detail_bloc.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/severity.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/ticket_penalty_detail.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/errors/failure.dart';
import 'package:marikina_market_mobile/core/router/mobile_route_access.dart';
import 'package:marikina_market_mobile/features/records/data/data_sources/records_remote_data_source.dart';
import 'package:marikina_market_mobile/features/records/data/repositories/records_repository_impl.dart';
import 'package:marikina_market_mobile/features/records/domain/enums/records_filter.dart';
import 'package:marikina_market_mobile/features/records/domain/entities/records_page_data.dart';
import 'package:marikina_market_mobile/features/records/domain/entities/vendor_ticket_detail.dart';
import 'package:marikina_market_mobile/features/records/data/models/vendor_ticket_detail_model.dart';
import 'package:marikina_market_mobile/features/records/domain/use_cases/load_records_use_case.dart';
import 'package:marikina_market_mobile/features/records/presentation/bloc/records/records_bloc.dart';
import 'package:marikina_market_mobile/features/records/presentation/bloc/records/load_records.dart';
import 'package:marikina_market_mobile/features/records/presentation/pages/records_page.dart';
import 'package:marikina_market_mobile/features/records/presentation/widgets/record_card.dart';
import 'package:marikina_market_mobile/features/records/presentation/widgets/vendor_record_detail_content.dart';
import 'package:marikina_market_mobile/features/records/presentation/widgets/vendor_ticket_paper_header.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/ticket_paper_header.dart';
import 'features/tickets/presentation/ticket_paper_layout_test.dart' show paper;
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
  'business_type': 'Public',
  'business_account_number': '2026-0001842',
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
  for (final severity in Severity.values) {
    testWidgets('vendor severity matches issued paper ${severity.value}', (
      tester,
    ) async {
      Widget frame(Widget child) => MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );
      await tester.pumpWidget(
        frame(
          TicketPenaltyDetail(
            severity: severity,
            penaltyType: PenaltyType.cashFine,
            totalFineAmount: 500,
            dueDate: DateTime.utc(2026, 10, 18),
          ),
        ),
      );
      final referenceText = tester.widget<Text>(find.text(severity.value));
      final referenceBadge = tester.widget<Container>(
        find
            .ancestor(
              of: find.text(severity.value),
              matching: find.byType(Container),
            )
            .first,
      );
      await tester.pumpWidget(
        frame(
          VendorRecordDetailContent(
            detail: VendorTicketDetailModel.fromJson({
              ...detailResponse,
              'severity': severity.value,
            }).toEntity(),
          ),
        ),
      );
      final actualText = tester.widget<Text>(find.text(severity.value));
      final actualBadge = tester.widget<Container>(
        find
            .ancestor(
              of: find.text(severity.value),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(actualText.style!.color, referenceText.style!.color);
      expect(actualBadge.decoration, referenceBadge.decoration);
      expect(tester.takeException(), isNull);
    });
  }
  const previews = bool.fromEnvironment('VENDOR_DETAIL_PREVIEWS');
  setUpAll(() async {
    if (!previews) return;
    final sdk = Platform.environment['FLUTTER_ROOT']!;
    final fonts = FontLoader('Roboto');
    for (final font in ['roboto-regular.ttf', 'roboto-bold.ttf']) {
      fonts.addFont(
        File(
          '$sdk/bin/cache/artifacts/material_fonts/$font',
        ).readAsBytes().then(ByteData.sublistView),
      );
    }
    await fonts.load();
    await (FontLoader('MaterialIcons')..addFont(
          File(
            '$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
          ).readAsBytes().then(ByteData.sublistView),
        ))
        .load();
  });

  for (final width in [280.0, 400.0]) {
    for (final ticket in [true, false]) {
      testWidgets(
        ticket
            ? 'citation header shows paper reference and system control at $width'
            : 'vendor header matches enforcer pixels $width ticket=$ticket',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          Future<ui.Image> render(Widget header) async {
            await tester.pumpWidget(
              MaterialApp(
                theme: AppTheme.light,
                home: Scaffold(
                  body: Padding(
                    padding: const EdgeInsets.all(20),
                    child: RepaintBoundary(
                      key: const ValueKey('header'),
                      child: header,
                    ),
                  ),
                ),
              ),
            );
            await tester.runAsync(
              () => precacheImage(
                const AssetImage('assets/logo/org_logo.png'),
                tester.element(find.byType(Scaffold)),
              ),
            );
            await tester.pumpAndSettle();
            return (await tester.runAsync(
              () => tester
                  .renderObject<RenderRepaintBoundary>(
                    find.byKey(const ValueKey('header')),
                  )
                  .toImage(),
            ))!;
          }

          if (ticket) {
            final image = await render(
              const TicketPaperHeader(
                isTicket: true,
                paperReference: '000456',
                controlNumber: 'TKT-2026-0042',
              ),
            );
            addTearDown(image.dispose);
            expect(find.text('PAPER REFERENCE:'), findsOneWidget);
            expect(find.text('000456'), findsOneWidget);
            expect(find.text('SYSTEM CONTROL:'), findsOneWidget);
            expect(find.text('#TKT-2026-0042'), findsOneWidget);
            expect(find.text('CONTROL NO.'), findsNothing);
            final header = tester.getRect(find.byKey(const ValueKey('header')));
            for (final element in find.byType(Text).evaluate()) {
              final bounds = tester.getRect(find.byWidget(element.widget));
              expect(bounds.left, greaterThanOrEqualTo(header.left));
              expect(bounds.right, lessThanOrEqualTo(header.right));
            }
            expect(tester.takeException(), isNull);
            return;
          }

          final reference = await render(
            TicketPaperHeader(
              isTicket: ticket,
              controlNumber: ticket ? 'TKT-2026-0042' : null,
            ),
          );
          final actual = await render(
            VendorTicketPaperHeader(
              isTicket: ticket,
              controlNumber: ticket ? 'TKT-2026-0042' : null,
            ),
          );
          addTearDown(reference.dispose);
          addTearDown(actual.dispose);
          expect(actual.width, reference.width);
          expect(actual.height, reference.height);
          final expectedBytes = await tester.runAsync(reference.toByteData);
          final actualBytes = await tester.runAsync(actual.toByteData);
          expect(
            actualBytes!.buffer.asUint8List(),
            orderedEquals(expectedBytes!.buffer.asUint8List()),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final width in [280.0, 400.0]) {
    for (final kind in [
      'Warning',
      'CashFine',
      'BloodDonation',
      'CommunityService',
    ]) {
      testWidgets('vendor paper fits $width with enlarged text: $kind', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final warning = kind == 'Warning';
        final fixture = VendorTicketDetailModel.fromJson({
          ...detailResponse,
          'type': warning ? 'Warning' : 'Ticket',
          'control_number': warning ? null : 'TKT-2026-00000000000000000042',
          'penalty_type': kind,
          if (kind == 'CommunityService') 'community_service_hours': 8,
        }).toEntity();
        await tester.pumpWidget(
          MaterialApp(
            theme: previews
                ? AppTheme.light.copyWith(
                    textTheme: AppTheme.light.textTheme.apply(
                      fontFamily: 'Roboto',
                    ),
                  )
                : AppTheme.light,
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 900),
                textScaler: const TextScaler.linear(2),
                disableAnimations: true,
              ),
              child: Scaffold(
                backgroundColor: AppTheme.ticketDetailBackground,
                body: SingleChildScrollView(
                  child: RepaintBoundary(
                    key: const ValueKey('vendor-paper'),
                    child: Padding(
                      padding: AppTheme.ticketDetailPadding,
                      child: VendorRecordDetailContent(detail: fixture),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.runAsync(
          () => precacheImage(
            const AssetImage('assets/logo/org_logo.png'),
            tester.element(find.byType(Scaffold)),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Reyes Fresh Seafood'), findsOneWidget);
        expect(find.text('Fish and Seafood Section'), findsOneWidget);
        expect(
          find.text('1st offense'),
          warning ? findsNothing : findsOneWidget,
        );
        expect(find.text('₱500.00'), warning ? findsNothing : findsNWidgets(2));
        expect(
          find.text('CONTROL NO.'),
          warning ? findsNothing : findsOneWidget,
        );
        expect(find.text('PENDING'), findsNothing);
        expect(find.text('Submit receipt'), findsNothing);
        expect(
          find.text('Photo Evidence Record'),
          warning ? findsNothing : findsOneWidget,
        );
        expect(find.text('Settlement Receipt'), findsNothing);
        expect(find.text('Community Service Log'), findsNothing);
        expect(tester.takeException(), isNull);
        if (previews) {
          await tester.runAsync(() async {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('vendor-paper')),
            );
            final image = await boundary.toImage();
            try {
              final png = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final folder = Directory('build/vendor-detail-previews');
              await folder.create(recursive: true);
              await File(
                '${folder.path}/vendor-$kind-${width.toInt()}-2x.png',
              ).writeAsBytes(png!.buffer.asUint8List());
            } finally {
              image.dispose();
            }
          });
        }
      });
    }
  }

  testWidgets('vendor and reference paper visual previews', (tester) async {
    if (!previews) return;
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final role in ['vendor', 'enforcer']) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light.copyWith(
            textTheme: AppTheme.light.textTheme.apply(fontFamily: 'Roboto'),
          ),
          home: Scaffold(
            backgroundColor: AppTheme.ticketDetailBackground,
            body: SingleChildScrollView(
              child: RepaintBoundary(
                key: const ValueKey('preview'),
                child: Padding(
                  padding: AppTheme.ticketDetailPadding,
                  child: role == 'vendor'
                      ? VendorRecordDetailContent(
                          detail: VendorTicketDetailModel.fromJson(
                            detailResponse,
                          ).toEntity(),
                        )
                      : paper(isTicket: true, control: '101'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => precacheImage(
          const AssetImage('assets/logo/org_logo.png'),
          tester.element(find.byType(Scaffold)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final image = await tester
            .renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('preview')),
            )
            .toImage();
        try {
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(
            'build/vendor-detail-previews',
          ).create(recursive: true);
          await File(
            'build/vendor-detail-previews/$role-400.png',
          ).writeAsBytes(png!.buffer.asUint8List());
        } finally {
          image.dispose();
        }
      });
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'vendor detail uses the issued paper header and ordinance layout',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 400,
                child: VendorRecordDetailContent(
                  detail: VendorTicketDetailModel.fromJson(
                    detailResponse,
                  ).toEntity(),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('VIOLATION TICKET'), findsOneWidget);
      final control = find.text('#101');
      expect(control, findsOneWidget);
      expect(
        tester.widget<Text>(control).style,
        AppTheme.ticketPaperControlStyle,
      );
      expect(find.text('PENDING'), findsNothing);
      final price = find.text('₱500.00').first;
      final code = find.text('SAMPLE-002');
      expect(
        (tester.getCenter(price).dy -
                tester.getCenter(find.text('1st offense')).dy)
            .abs(),
        lessThanOrEqualTo(3),
      );
      expect(
        tester.getTopLeft(price).dy,
        greaterThan(tester.getBottomLeft(code).dy),
      );
      expect(
        tester.getTopRight(price).dx,
        greaterThan(tester.getTopRight(code).dx),
      );
      expect(find.text('Reyes Fresh Seafood'), findsOneWidget);
      expect(find.text('Submit receipt'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

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
      expect(find.text('Records • 10'), findsOneWidget);
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
    expect(find.text('Unable to load records'), findsOneWidget);
    expect(find.text('Unavailable right now.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('No records found'), findsOneWidget);
    expect(
      find.text(
        'Try changing your search or record type. New records will appear here.',
      ),
      findsOneWidget,
    );
    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'View Details uses the vendor endpoint and Back refreshes the Records list',
    (tester) async {
      final paths = <String>[];
      var recordStatus = 'Pending';
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
                  'items': [
                    {...recordResponse, 'ticket_status': recordStatus},
                  ],
                  'has_more': false,
                  'total': 1,
                }
              : detailResponse,
        );
      });
      late RecordsBloc recordsBloc;
      late RecordDetailBloc detailBloc;
      late VendorSettlementBloc settlementBloc;
      await tester.runAsync(() async {
        recordsBloc = RecordsBloc(LoadRecordsUseCase(repository));
        detailBloc = RecordDetailBloc(LoadRecordDetailUseCase(repository));
        settlementBloc = VendorSettlementBloc(
          loadReceipt: LoadVendorReceiptUseCase(repository),
          loadProgress: LoadVendorServiceProgressUseCase(repository),
        );
      });
      sl.registerFactory<RecordsBloc>(() => recordsBloc);
      sl.registerFactory<RecordDetailBloc>(() => detailBloc);
      sl.registerFactory<VendorSettlementBloc>(() => settlementBloc);
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
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp.router(theme: AppTheme.light, routerConfig: router),
        );
        if (recordsBloc.state.isInitialLoading) {
          await recordsBloc.stream
              .firstWhere((state) => !state.isInitialLoading)
              .timeout(const Duration(seconds: 5));
        }
      });
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('View Details ›'));
        await tester.pump();
        if (detailBloc.state.isLoading) {
          await detailBloc.stream
              .firstWhere((state) => !state.isLoading)
              .timeout(const Duration(seconds: 5));
        }
      });
      await tester.runAsync(() async {
        await tester.pump();
        if (!settlementBloc.state.isLoaded) {
          await settlementBloc.stream
              .firstWhere((state) => state.isLoaded)
              .timeout(const Duration(seconds: 5));
        }
      });
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, '/vendor/records/101');
      expect(find.text('Reyes Fresh Seafood'), findsOneWidget);
      expect(paths, [
        '/vendor/tickets/inspections',
        '/vendor/tickets/101',
        '/vendor/tickets/101/settlement/receipt',
      ]);
      recordStatus = 'Paid';
      await tester.runAsync(() async {
        await tester.tap(find.byTooltip('Back to records'));
        await tester.pump();
        await Future<void>.delayed(Duration.zero);
        if (recordsBloc.state.isRefreshing) {
          await recordsBloc.stream
              .firstWhere((state) => !state.isRefreshing)
              .timeout(const Duration(seconds: 5));
        }
      });
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/vendor/records');
      expect(find.text('My Records'), findsOneWidget);
      expect(paths, [
        '/vendor/tickets/inspections',
        '/vendor/tickets/101',
        '/vendor/tickets/101/settlement/receipt',
        '/vendor/tickets/inspections',
      ]);
      expect(find.text('Paid'), findsOneWidget);
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
    'records paging failure preserves data and retry appends once',
    () async {
      final queries = <Map<String, Object?>>[];
      final repository = recordsRepository((options) async {
        queries.add(Map<String, Object?>.from(options.queryParameters));
        if (queries.length == 2) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          );
        }
        return reply(options, {
          'items': [
            {...recordResponse, 'ticket_id': queries.length == 1 ? 101 : 102},
          ],
          'has_more': queries.length == 1,
          'total': 2,
        });
      });
      final bloc = RecordsBloc(LoadRecordsUseCase(repository));
      addTearDown(bloc.close);
      await fetch(bloc, const LoadRecords());
      await fetch(bloc, const LoadRecords(offset: 1));
      expect(bloc.state.items.map((item) => item.ticketId), [101]);
      expect(bloc.state.isLoadMoreError, isTrue);
      expect(bloc.state.isLoadingMore, isFalse);
      expect(bloc.state.hasMore, isTrue);
      expect(bloc.state.error, isNotNull);
      await fetch(bloc, const LoadRecords(offset: 1));
      expect(bloc.state.items.map((item) => item.ticketId), [101, 102]);
      expect(bloc.state.isLoadMoreError, isFalse);
      expect(bloc.state.isLoadingMore, isFalse);
      expect(bloc.state.error, isNull);
      expect(bloc.state.hasMore, isFalse);
      expect(queries.map((query) => query['offset']), [0, 1, 1]);
    },
  );
  test(
    'records query change resets paging and ignores an old pending page',
    () async {
      final started = Completer<RequestOptions>();
      final pending = Completer<Response<Object?>>();
      final queries = <Map<String, Object?>>[];
      final repository = recordsRepository((options) async {
        queries.add(Map<String, Object?>.from(options.queryParameters));
        if (queries.length == 2) {
          started.complete(options);
          return pending.future;
        }
        final changed = queries.length > 2;
        return reply(options, {
          'items': [
            {
              ...recordResponse,
              'ticket_id': changed ? 201 : 101,
              'type': changed ? 'Warning' : 'Ticket',
            },
          ],
          'has_more': !changed,
          'total': changed ? 1 : 2,
        });
      });
      final bloc = RecordsBloc(LoadRecordsUseCase(repository));
      addTearDown(bloc.close);
      await fetch(bloc, const LoadRecords());
      bloc.add(const LoadRecords(offset: 1));
      final options = await started.future;
      await fetch(
        bloc,
        const LoadRecords(
          search: 'market & attire',
          filter: RecordsFilter.warning,
        ),
      );
      expect(queries, [
        {'offset': 0},
        {'offset': 1},
        {'offset': 0, 'search': 'market & attire', 'type': 'Warning'},
      ]);
      expect(bloc.state.items.map((item) => item.ticketId), [201]);
      final afterChange = <List<int>>[];
      final subscription = bloc.stream.listen(
        (state) =>
            afterChange.add(state.items.map((item) => item.ticketId).toList()),
      );
      pending.complete(
        reply(options, {
          'items': [
            {...recordResponse, 'ticket_id': 102},
          ],
          'has_more': false,
          'total': 2,
        }),
      );
      // Keep the BLoC open while the HTTP/interceptor continuation completes.
      // A separate negative-control run checks sensitivity to a late append.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await subscription.cancel();
      expect(afterChange, isEmpty);
      expect(bloc.state.items.map((item) => item.ticketId), [201]);
      expect(bloc.state.search, 'market & attire');
      expect(bloc.state.filter, RecordsFilter.warning);
      expect(bloc.state.total, 1);
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
