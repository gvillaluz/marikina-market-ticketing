import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ticket_summary_model.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/ticket_card.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/pages/ticket_detail_page.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/pages/tickets_page.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/bloc/ticket_state.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/bloc/ticket_event.dart';
import 'features/tickets/presentation/ticket_refresh_test.dart'
    show ticketResponse, refreshBloc, loadFirstPage;
import 'features/auth/data/login_mobile_contract_test.dart'
    show contractClient, reply;

void main() {
  testWidgets(
    'warning details support null settlement status and large text at 280px',
    (tester) async {
      tester.view.physicalSize = const Size(280, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final client = contractClient(
        (options) async => reply(options, {
          'ticket_id': 42,
          'enforcer_id': 7,
          'vendor_id': 12,
          'type': 'Warning',
          'vendor_type': 'Public',
          'business_id': 'BUS-12',
          'business_name': 'Market Goods',
          'first_name': 'Maria Isabel',
          'last_name': 'Dela Cruz Santos',
          'violations': [],
          'issued_at': '2026-10-07T08:00:00Z',
          'market_section_name': 'Section A',
          'categories': [],
          'description': 'Keep the stall and its surroundings clean.',
        }),
      );
      addTearDown(client.dio.close);
      final bloc = refreshBloc(client);
      addTearDown(bloc.close);
      await tester.runAsync(() async {
        final loaded = bloc.stream.firstWhere(
          (state) => state is TicketDetailLoaded,
        );
        bloc.add(LoadTicketDetail(42));
        await loaded;
      });
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
              child: const TicketDetailPage(ticketId: 42),
            ),
          ),
        ),
      );
      expect(find.text('WRITTEN WARNING'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  testWidgets(
    'ticket card wraps status, long control number, and dates at 280px',
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
                child: TicketCard(
                  ticketSummary: TicketSummaryModel.fromJson({
                    ...ticketResponse,
                    'control_number': 'TKT-2026-0000000042',
                    'status': 'Contested',
                  }).toEntity(),
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Contested'), findsOneWidget);
    },
  );
  testWidgets('changing ticket status cancels pending search debounce', (
    tester,
  ) async {
    var calls = 0;
    final client = contractClient((options) async {
      calls++;
      return reply(options, {'items': [], 'has_more': false});
    });
    addTearDown(client.dio.close);
    final bloc = refreshBloc(client);
    addTearDown(bloc.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: TicketsPage()),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Market');
    await tester.tap(find.widgetWithText(ChoiceChip, TicketStatus.paid.value));
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('detail load failure stays on screen with retry', (tester) async {
    var calls = 0;
    final client = contractClient((options) async {
      calls++;
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    });
    addTearDown(client.dio.close);
    final bloc = refreshBloc(client);
    addTearDown(bloc.close);
    await tester.runAsync(() async {
      final failed = bloc.stream.firstWhere((state) => state is TicketError);
      bloc.add(LoadTicketDetail(42));
      await failed;
    });
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const TicketDetailPage(ticketId: 42),
        ),
      ),
    );
    expect(find.text('Unable to load ticket details'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('Unable to load ticket details'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  test(
    'duplicate ticket refreshes use one request and keep empty results on failure',
    () async {
      var calls = 0;
      final started = Completer<RequestOptions>();
      final pending = Completer<Response<Object?>>();
      final client = contractClient((options) async {
        if (++calls == 1) {
          return reply(options, {'items': [], 'has_more': false});
        }
        started.complete(options);
        return pending.future;
      });
      addTearDown(client.dio.close);
      final bloc = refreshBloc(client);
      addTearDown(bloc.close);
      await loadFirstPage(bloc);
      bloc.add(LoadTicketSummary());
      final options = await started.future;
      bloc.add(LoadTicketSummary());
      await Future<void>.delayed(Duration.zero);
      expect(calls, 2);
      final finished = bloc.stream.firstWhere(
        (state) =>
            state is TicketsLoaded &&
            !state.isRefreshing &&
            state.errorMessage != null,
      );
      pending.completeError(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      );
      await finished;
      expect((bloc.state as TicketsLoaded).ticketSummary, isEmpty);
    },
  );
}
