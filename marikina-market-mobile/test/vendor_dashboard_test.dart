import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/features/dashboard/data/models/vendor_dashboard_model.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/network/client.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/errors/failure.dart';
import 'package:marikina_market_mobile/features/auth/data/models/user_model.dart';
import 'package:marikina_market_mobile/features/dashboard/data/data_sources/vendor_dashboard_remote_data_source.dart';
import 'package:marikina_market_mobile/features/dashboard/data/repositories/vendor_dashboard_repository_impl.dart';
import 'package:marikina_market_mobile/features/dashboard/domain/entities/vendor_dashboard_summary.dart';
import 'package:marikina_market_mobile/features/dashboard/domain/use_cases/load_vendor_dashboard_use_case.dart';
import 'package:marikina_market_mobile/features/dashboard/presentation/bloc/vendor_dashboard_bloc.dart';
import 'dart:async';
import 'package:marikina_market_mobile/features/dashboard/presentation/pages/vendor_dashboard_page.dart';
import 'features/auth/data/login_mobile_contract_test.dart'
    show contractClient, reply;
import 'vendor_profile_session_test.dart' show vendorAccount;
import 'profile_preview_capture.dart';
import 'records_feature_test.dart' show detailResponse, recordResponse;
import 'package:marikina_market_mobile/features/records/data/models/vendor_ticket_detail_model.dart';
import 'package:marikina_market_mobile/features/records/data/models/vendor_record_model.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/skeleton_box.dart';
import 'package:marikina_market_mobile/features/dashboard/presentation/bloc/load_vendor_dashboard.dart';

VendorDashboardBloc vendorDashboardBloc(ApiClient client) =>
    VendorDashboardBloc(
      LoadVendorDashboardUseCase(
        VendorDashboardRepositoryImpl(VendorDashboardRemoteDataSource(client)),
      ),
    );

const dashboardResponse = <String, Object?>{
  'total_warnings': 2,
  'total_tickets': 4,
  'compliance': {
    'compliance_score': 85,
    'standing': 'Good Standing',
    'violation_frequency_level': 'Low',
    'days_since_last_ticket': 14,
    'category_severity_level': 'Moderate',
    'penalty_payment_history': 96.0,
  },
  'tasks': [
    {
      'ticket_id': 41,
      'control_number': 'TKT-0041',
      'penalty_type': 'CashFine',
      'hours_required': null,
      'hours_completed': 0,
    },
    {
      'ticket_id': 42,
      'control_number': 'TKT-0042',
      'penalty_type': 'BloodDonation',
      'hours_required': null,
      'hours_completed': 0,
    },
    {
      'ticket_id': 43,
      'control_number': 'TKT-0043',
      'penalty_type': 'CommunityService',
      'hours_required': 8,
      'hours_completed': 2.5,
    },
  ],
};

void main() {
  setUpAll(loadProfilePreviewFonts);
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  testWidgets(
    'initial loading uses skeletons and refresh keeps the loaded dashboard',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late Completer<void> gate;
      final client = contractClient((options) async {
        await gate.future;
        return reply(options, dashboardResponse);
      });
      addTearDown(client.dio.close);
      late VendorDashboardBloc bloc;
      await tester.runAsync(() async {
        gate = Completer<void>();
        bloc = vendorDashboardBloc(client);
        final loading = bloc.stream.firstWhere((state) => state.isLoading);
        bloc.add(const LoadVendorDashboard());
        await loading;
      });
      addTearDown(() {
        unawaited(bloc.close());
      });
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: profilePreviewTheme,
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(390, 844),
                disableAnimations: true,
              ),
              child: Scaffold(
                body: BlocProvider.value(
                  value: bloc,
                  child: VendorDashboardPage(
                    user: UserModel.fromJson(vendorAccount).toEntity(),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(SkeletonBox), findsWidgets);
      expect(find.text('85/100'), findsNothing);
      await captureProfilePreview(tester, key, 'dashboard-loading');
      await tester.runAsync(() async {
        final loaded = bloc.stream.firstWhere(
          (state) => state.summary != null && !state.isLoading,
        );
        gate.complete();
        await loaded;
      });
      await tester.pumpAndSettle();
      expect(find.byType(SkeletonBox), findsNothing);
      await tester.runAsync(() async {
        gate = Completer<void>();
        final loading = bloc.stream.firstWhere((state) => state.isLoading);
        bloc.add(const LoadVendorDashboard());
        await loading;
      });
      await tester.pump();
      expect(find.byType(SkeletonBox), findsNothing);
      expect(find.text('85/100'), findsOneWidget);
      await tester.runAsync(() async {
        final loaded = bloc.stream.firstWhere((state) => !state.isLoading);
        gate.complete();
        await loaded;
      });
      await tester.pumpWidget(const SizedBox());
    },
  );
  test(
    'InProgress tickets can be parsed in the existing record list and detail',
    () {
      final detail = VendorTicketDetailModel.fromJson({
        ...detailResponse,
        'status': 'InProgress',
      }).toEntity();
      final record = VendorRecordModel.fromJson({
        ...recordResponse,
        'ticket_status': 'InProgress',
      }).toEntity();
      expect(detail.status, TicketStatus.inProgress);
      expect(record.status, TicketStatus.inProgress);
      expect(detail.status!.label, 'In Progress');
    },
  );
  test(
    'dashboard maps the API score, lifetime counts and each penalty task',
    () {
      final data = const VendorDashboardModel(dashboardResponse).toEntity();
      expect(data.totalWarnings, 2);
      expect(data.totalTickets, 4);
      expect(data.compliance.score, 85);
      expect(data.compliance.daysSinceLastTicket, 14);
      expect(data.tasks.map((task) => task.penaltyType), PenaltyType.values);
      expect(data.tasks.last.progress, .3125);
    },
  );

  test(
    'dashboard handles denied and malformed responses without fabricated data',
    () async {
      for (final status in [403, 200]) {
        final client = contractClient((options) async {
          expect(options.path, '/vendor/dashboard');
          if (status == 403) {
            throw DioException(
              requestOptions: options,
              response: Response<Object?>(
                requestOptions: options,
                statusCode: 403,
                data: {'message': 'Access denied.'},
              ),
              type: DioExceptionType.badResponse,
            );
          }
          return reply(options, {...dashboardResponse, 'total_tickets': -1});
        });
        final result = await VendorDashboardRepositoryImpl(
          VendorDashboardRemoteDataSource(client),
        ).loadDashboard();
        expect(result, isA<ResultFailure<VendorDashboardSummary>>());
        if (status == 403) {
          expect((result as ResultFailure).failure, isA<UnauthorizedFailure>());
        }
        client.dio.close();
      }
    },
  );

  for (final compact in [false, true]) {
    testWidgets(
      'dashboard displays the reference content at ${compact ? '280px large text' : '390px'}',
      (tester) async {
        tester.view.physicalSize = Size(compact ? 280 : 390, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final client = contractClient(
          (options) async => reply(options, dashboardResponse),
        );
        addTearDown(client.dio.close);
        late VendorDashboardBloc bloc;
        await tester.runAsync(() async {
          bloc = vendorDashboardBloc(client);
          await bloc.refresh();
        });
        addTearDown(() {
          unawaited(bloc.close());
        });
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: profilePreviewTheme,
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(compact ? 280 : 390, 1100),
                  textScaler: TextScaler.linear(compact ? 2 : 1),
                ),
                child: Scaffold(
                  body: BlocProvider.value(
                    value: bloc,
                    child: VendorDashboardPage(
                      user: UserModel.fromJson(vendorAccount).toEntity(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        final ring = find.byType(CircularProgressIndicator);
        expect(tester.widget<CircularProgressIndicator>(ring).value, 0);
        await tester.pump(const Duration(milliseconds: 1000));
        expect(tester.widget<CircularProgressIndicator>(ring).value, .85);
        expect(find.text('85/100'), findsOneWidget);
        expect(find.text('Total warnings'), findsOneWidget);
        expect(find.text('Total violation tickets'), findsOneWidget);
        expect(find.text('Pay pending ticket'), findsOneWidget);
        expect(find.text('Upload settlement proof'), findsOneWidget);
        expect(find.text('Complete Community Service'), findsOneWidget);
        expect(find.text('2.5 / 8 hours completed'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await captureProfilePreview(
          tester,
          key,
          'vendor-dashboard-${compact ? '280-2x' : '390-1x'}',
        );
        if (compact) {
          await tester.ensureVisible(find.text('View Details'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await captureProfilePreview(
            tester,
            key,
            'vendor-dashboard-280-2x-tasks',
          );
        }
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'dashboard retries to an empty task list and preserves data on refresh failure',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var offline = true;
      final client = contractClient((options) async {
        if (offline) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          );
        }
        return reply(options, {
          ...dashboardResponse,
          'total_warnings': 0,
          'total_tickets': 0,
          'compliance': {
            ...dashboardResponse['compliance'] as Map<String, Object?>,
            'compliance_score': 100,
            'days_since_last_ticket': null,
            'category_severity_level': 'Low',
            'penalty_payment_history': 100,
          },
          'tasks': [],
        });
      });
      addTearDown(client.dio.close);
      late VendorDashboardBloc bloc;
      await tester.runAsync(() async {
        bloc = vendorDashboardBloc(client);
        await bloc.refresh();
      });
      addTearDown(() {
        unawaited(bloc.close());
      });
      final previewKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: previewKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: profilePreviewTheme,
            home: Scaffold(
              body: BlocProvider.value(
                value: bloc,
                child: VendorDashboardPage(
                  user: UserModel.fromJson(vendorAccount).toEntity(),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text("We couldn't load your dashboard"), findsOneWidget);
      await captureProfilePreview(tester, previewKey, 'dashboard-error');
      offline = false;
      await tester.runAsync(() async {
        final ready = bloc.stream.firstWhere(
          (state) => state.summary != null && !state.isLoading,
        );
        await tester.tap(find.text('Try again'));
        await ready;
      });
      await tester.pumpAndSettle();
      expect(find.text('Compliance Tasks'), findsOneWidget);
      expect(find.text('No active tickets'), findsOneWidget);
      expect(find.text('No tickets'), findsOneWidget);
      await captureProfilePreview(
        tester,
        previewKey,
        'dashboard-no-active-tickets',
      );
      offline = true;
      await tester.runAsync(bloc.refresh);
      await tester.pumpAndSettle();
      expect(find.text('100/100'), findsOneWidget);
      expect(find.text("Couldn't refresh your dashboard"), findsOneWidget);
      expect(
        find.textContaining('No internet connection. Please try again.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Your last loaded information is shown below.'),
        findsOneWidget,
      );
      await captureProfilePreview(
        tester,
        previewKey,
        'dashboard-refresh-error',
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('each task opens its own vendor record and refreshes on return', (
    tester,
  ) async {
    var loads = 0;
    final client = contractClient((options) async {
      loads++;
      return reply(options, dashboardResponse);
    });
    addTearDown(client.dio.close);
    late VendorDashboardBloc bloc;
    await tester.runAsync(() async {
      bloc = vendorDashboardBloc(client);
      await bloc.refresh();
    });
    addTearDown(() {
      unawaited(bloc.close());
    });
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: BlocProvider.value(
              value: bloc,
              child: VendorDashboardPage(
                user: UserModel.fromJson(vendorAccount).toEntity(),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/vendor/records/:ticketId',
          name: Routes.vendorRecordDetailName,
          builder: (_, state) => Scaffold(
            body: Text('Record ${state.pathParameters['ticketId']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: profilePreviewTheme, routerConfig: router),
    );
    await tester.pumpAndSettle();
    for (final (label, id) in [
      ('Review', 41),
      ('Upload', 42),
      ('View Details', 43),
    ]) {
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(find.text('Record $id'), findsOneWidget);
      await tester.runAsync(() async {
        final refreshed = bloc.stream.firstWhere((state) => !state.isLoading);
        router.pop();
        await refreshed;
      });
      await tester.pumpAndSettle();
    }
    expect(loads, 4);
    await tester.pumpWidget(const SizedBox());
  });
}
