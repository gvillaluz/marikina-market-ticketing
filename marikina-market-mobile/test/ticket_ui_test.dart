import 'dart:async';
import 'package:marikina_market_mobile/features/tickets/data/models/violation_summary_model.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/ticket_violation_section.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/severity.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/ticket_penalty_detail.dart';
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
  for (final isTicket in [true, false]) {
    testWidgets(
      'ordinance format and preview row spacing for ticket=$isTicket',
      (tester) async {
        tester.view.physicalSize = Size(isTicket ? 400 : 280, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final violation = ViolationSummaryModel.fromJson({
          'ordinance_id': 11,
          'ordinance_no': '11',
          'series': '2014',
          'ordinance_code': 'SEC-8',
          'offense_count': 2,
          'penalty_amount': 1500,
        }).toEntity();
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: SingleChildScrollView(
                padding: AppTheme.ticketCardPadding,
                child: TicketViolationSection(
                  penaltyType: PenaltyType.cashFine,
                  violations: [violation],
                  description: 'Obstruction',
                  marketSection: 'Dry Goods',
                  categories: [],
                  isTicket: isTicket,
                ),
              ),
            ),
          ),
        );
        expect(find.text('Ord No. 11, Series of 2014'), findsOneWidget);
        expect(
          tester.getTopLeft(find.text('SEC-8')).dy -
              tester.getBottomLeft(find.text('Ord No. 11, Series of 2014')).dy,
          6,
        );
        expect(
          find.text('2nd offense'),
          isTicket ? findsOneWidget : findsNothing,
        );
        expect(
          find.text('₱1,500.00'),
          isTicket ? findsOneWidget : findsNothing,
        );
        if (isTicket) {
          final row = find.ancestor(
            of: find.text('2nd offense'),
            matching: find.byType(Align),
          );
          expect(
            tester.getTopLeft(row).dy -
                tester.getBottomLeft(find.text('SEC-8')).dy,
            12,
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('cash detail rows and total wrap at 280px with enlarged text', (
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
              padding: AppTheme.ticketCardPadding,
              child: TicketPenaltyDetail(
                severity: Severity.high,
                penaltyType: PenaltyType.cashFine,
                totalFineAmount: 1234567.89,
                dueDate: DateTime(2026, 10, 26),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('₱1,234,567.89'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final penalty in PenaltyType.values) {
    testWidgets('ticket detail total is cash-only for ${penalty.name}', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: TicketPenaltyDetail(
                severity: Severity.moderate,
                penaltyType: penalty,
                dueDate: DateTime(2026, 10, 26),
                totalFineAmount: 12500.50,
                communityHrs: 3,
              ),
            ),
          ),
        ),
      );
      if (penalty == PenaltyType.cashFine) {
        expect(find.text('₱12,500.50'), findsOneWidget);
        final panel = find
            .ancestor(
              of: find.text('Total Fine Due:'),
              matching: find.byType(Container),
            )
            .first;
        expect(
          tester.getSize(panel).width,
          tester.getSize(find.byType(Scaffold)).width,
        );
      } else {
        expect(find.text('Total Fine Due:'), findsNothing);
      }
      expect(tester.takeException(), isNull);
    });
  }

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
