import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/skeleton_box.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/connectivity/cubit/connectivity_cubit.dart';
import 'package:marikina_market_mobile/features/auth/data/models/user_model.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:marikina_market_mobile/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:marikina_market_mobile/features/dashboard/data/data_sources/dashboard_remote_data_source.dart';
import 'package:marikina_market_mobile/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:marikina_market_mobile/features/dashboard/domain/use_cases/load_dashboard_summary_use_case.dart';
import 'package:marikina_market_mobile/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:marikina_market_mobile/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:marikina_market_mobile/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:marikina_market_mobile/features/dashboard/presentation/widgets/count_card.dart';
import 'package:marikina_market_mobile/features/dashboard/presentation/widgets/dashboard_metric_layout.dart';
import 'package:marikina_market_mobile/features/dashboard/presentation/widgets/weekly_overview_section.dart';

import 'features/auth/data/login_mobile_contract_test.dart'
    show contractClient, reply, profileResponse;
import 'features/auth/login_mobile_flow_test.dart' show loginBloc;
import 'features/auth/login_test_network_info.dart';

// API-shaped aggregate: two tickets and one warning produce three records.
const summaryResponse = <String, Object?>{
  'ticket_recorded': 2,
  'warning_recorded': 1,
  'total_recorded': 3,
};

DashboardBloc dashboardBloc(
  Future<Response<Object?>> Function(RequestOptions) respond,
) {
  final client = contractClient(respond);
  addTearDown(client.dio.close);
  final bloc = DashboardBloc(
    loadDashboardSummaryUseCase: LoadDashboardSummaryUseCase(
      DashboardRepositoryImpl(DashboardRemoteDataSourceImpl(client)),
    ),
  );
  addTearDown(bloc.close);
  return bloc;
}

Future<void> loadSummary(WidgetTester tester, DashboardBloc bloc) async {
  bloc.add(LoadDashboardSummary());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 20));
  expect(
    bloc.state,
    anyOf(isA<DashboardSummaryLoaded>(), isA<DashboardError>()),
  );
}

Future<void> showOverview(
  WidgetTester tester,
  DashboardBloc bloc, {
  bool disableAnimations = true,
}) => tester.pumpWidget(
  BlocProvider.value(
    value: bloc,
    child: MaterialApp(
      theme: AppTheme.light,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: WeeklyOverviewSection(),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  setUp(
    () => FlutterSecureStorage.setMockInitialValues({
      'access_token': 'test-access-token',
    }),
  );

  for (final disableAnimations in [true, false]) {
    testWidgets(
      'refresh progress exposes valid semantics: disableAnimations=$disableAnimations',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final release = Completer<void>();
        var calls = 0;
        final bloc = dashboardBloc((options) async {
          if (++calls > 1) await release.future;
          return reply(options, summaryResponse);
        });
        try {
          await loadSummary(tester, bloc);
          await showOverview(
            tester,
            bloc,
            disableAnimations: disableAnimations,
          );
          bloc.add(LoadDashboardSummary());
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 20));
          expect(calls, 2);
          final indicator = find.byType(CircularProgressIndicator);
          expect(indicator, findsOneWidget);
          final data = tester.getSemantics(indicator).getSemanticsData();
          expect(data.label, 'Refreshing overview');
          expect(data.value, disableAnimations ? '75' : '');
          expect(data.minValue, disableAnimations ? '0' : isNull);
          expect(data.maxValue, disableAnimations ? '100' : isNull);
          expect(tester.takeException(), isNull);
        } finally {
          if (!release.isCompleted) release.complete();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 20));
          await tester.pumpWidget(const SizedBox.shrink());
          semantics.dispose();
        }
      },
    );
  }

  testWidgets(
    'refresh preserves counters, coalesces requests, and retains data on failure',
    (tester) async {
      var calls = 0;
      final releaseFailure = Completer<void>();
      RequestOptions? refreshRequest;
      final bloc = dashboardBloc((options) async {
        calls++;
        if (calls == 1) return reply(options, summaryResponse);
        refreshRequest = options;
        await releaseFailure.future;
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      });
      final states = <DashboardState>[];
      final subscription = bloc.stream.listen(states.add);
      addTearDown(subscription.cancel);
      try {
        await loadSummary(tester, bloc);
        await showOverview(tester, bloc);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('1'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
        final cardsBefore = tester
            .widgetList<CountCard>(find.byType(CountCard))
            .toList();
        bloc.add(LoadDashboardSummary());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 20));
        expect(calls, 2);
        expect(refreshRequest!.method, 'GET');
        expect(refreshRequest!.path, '/enforcer/tickets/dashboard');
        bloc.add(LoadDashboardSummary());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 20));
        expect(calls, 2);
        expect(
          states.whereType<DashboardSummaryLoaded>().where(
            (state) => state.isRefreshing,
          ),
          hasLength(1),
        );
        expect(find.byType(CountCard), findsNWidgets(3));
        expect(find.byType(SkeletonBox), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        final cardsDuring = tester
            .widgetList<CountCard>(find.byType(CountCard))
            .toList();
        for (var index = 0; index < cardsBefore.length; index++) {
          expect(identical(cardsBefore[index], cardsDuring[index]), isTrue);
        }
        releaseFailure.complete();
        await tester.pumpAndSettle(
          const Duration(milliseconds: 20),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 2),
        );
        expect(bloc.state, isA<DashboardSummaryLoaded>());
        final loaded = bloc.state as DashboardSummaryLoaded;
        expect(loaded.isRefreshing, isFalse);
        expect(
          loaded.errorMessage,
          'No internet connection. Please try again.',
        );
        expect(find.text('2'), findsOneWidget);
        expect(find.text('1'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
        expect(
          find.text('No internet connection. Please try again.'),
          findsOneWidget,
        );
        expect(find.text('Try again'), findsOneWidget);
        expect(calls, 2);
        expect(tester.takeException(), isNull);
      } finally {
        if (!releaseFailure.isCompleted) releaseFailure.complete();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 20));
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );

  testWidgets(
    'initial failure shows its domain message and retry loads the overview',
    (tester) async {
      var calls = 0;
      final bloc = dashboardBloc((options) async {
        if (++calls == 1) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          );
        }
        return reply(options, summaryResponse);
      });
      await loadSummary(tester, bloc);
      await showOverview(tester, bloc);
      expect(
        find.text('No internet connection. Please try again.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.byType(CountCard), findsNWidgets(3));
      expect(calls, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('zero activity has an explicit empty state and zero counters', (
    tester,
  ) async {
    final bloc = dashboardBloc(
      (options) async => reply(options, {
        'ticket_recorded': 0,
        'warning_recorded': 0,
        'total_recorded': 0,
      }),
    );
    await loadSummary(tester, bloc);
    await showOverview(tester, bloc);
    expect(find.text('No activity this week'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(3));
    expect(find.text('Total this week'), findsOneWidget);
  });

  testWidgets('counter cards fit at 280px with large text and large counts', (
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
          child: const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: DashboardMetricLayout(
                children: [
                  CountCard(type: 'Ticket', count: 1234567, compact: true),
                  CountCard(type: 'Warning', count: 1234567, compact: true),
                  CountCard(type: 'Total', count: 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Total this week'), findsOneWidget);
    final cards = find.byType(CountCard);
    expect(
      tester.getTopLeft(cards.at(0)).dy,
      tester.getTopLeft(cards.at(1)).dy,
    );
    expect(tester.getSize(cards.at(0)), tester.getSize(cards.at(1)));
    expect(
      tester.getTopLeft(cards.at(2)).dy,
      greaterThan(tester.getBottomLeft(cards.at(0)).dy),
    );
    expect(tester.getSize(cards.at(2)).width, 240);
  });

  testWidgets(
    'dashboard fits a narrow screen with large text, a long name, and offline status',
    (tester) async {
      tester.view.physicalSize = const Size(280, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final connectivity = ConnectivityCubit(LoginTestNetworkInfo());
      addTearDown(connectivity.close);
      final auth = loginBloc(
        connectivity,
        (options) async => reply(options, profileResponse),
      );
      try {
        await auth.stream.firstWhere((state) => state is Unauthenticated);
        final authenticated = auth.stream.firstWhere(
          (state) => state is Authenticated,
        );
        auth.add(
          UserUpdated(
            UserModel.fromJson({
              ...profileResponse,
              'firstName': 'Maria Isabel',
              'lastName': 'Dela Cruz Santos',
            }).toEntity(),
          ),
        );
        await authenticated;
        final bloc = dashboardBloc(
          (options) async => reply(options, summaryResponse),
        );
        await loadSummary(tester, bloc);
        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<DashboardBloc>.value(value: bloc),
              BlocProvider<AuthBloc>.value(value: auth),
              BlocProvider<ConnectivityCubit>.value(value: connectivity),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              home: MediaQuery(
                data: const MediaQueryData(
                  disableAnimations: true,
                  textScaler: TextScaler.linear(2),
                ),
                child: const Scaffold(body: DashboardPage()),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('Welcome, Maria Isabel Dela Cruz Santos'),
          findsOneWidget,
        );
        expect(find.text('Offline'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -500),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        unawaited(auth.close());
      }
    },
  );

  testWidgets(
    'overview keeps paired counters and a separate total with large text',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final bloc = dashboardBloc(
        (options) async => reply(options, summaryResponse),
      );
      await loadSummary(tester, bloc);
      await showOverview(tester, bloc);
      final cards = find.byType(CountCard);
      expect(
        tester.getTopLeft(cards.at(0)).dy,
        tester.getTopLeft(cards.at(1)).dy,
      );
      expect(
        tester.getTopLeft(cards.at(1)).dx,
        greaterThan(tester.getTopLeft(cards.at(0)).dx),
      );
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: MaterialApp(
            theme: AppTheme.light,
            home: MediaQuery(
              data: const MediaQueryData(
                disableAnimations: true,
                textScaler: TextScaler.linear(2),
              ),
              child: const Scaffold(
                body: SingleChildScrollView(child: WeeklyOverviewSection()),
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getTopLeft(cards.at(1)).dy,
        tester.getTopLeft(cards.at(0)).dy,
      );
      expect(
        tester.getTopLeft(cards.at(2)).dy,
        greaterThan(tester.getBottomLeft(cards.at(0)).dy),
      );
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'refresh future completes after the current request and ignores duplicate loads',
    () async {
      final pending = Completer<Response<Object?>>();
      final started = Completer<RequestOptions>();
      var calls = 0;
      final bloc = dashboardBloc((options) {
        calls++;
        started.complete(options);
        return pending.future;
      });
      final first = bloc.refresh();
      final options = await started.future;
      final second = bloc.refresh();
      await Future<void>.delayed(Duration.zero);
      expect(calls, 1);
      pending.complete(reply(options, summaryResponse));
      await Future.wait([first, second]);
      expect(
        (bloc.state as DashboardSummaryLoaded).dashboardSummary.totalRecorded,
        3,
      );
    },
  );
}
