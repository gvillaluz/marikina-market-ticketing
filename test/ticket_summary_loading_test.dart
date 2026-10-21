import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/page_result.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/data/data_sources/ticket_remote_data_source.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/inspection_summary_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ticket_summary_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/repositories/ticket_repository_impl.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ticket_summary.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/inspection_card.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/bloc/ticket_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/bloc/ticket_event.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/bloc/ticket_state.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/ticket_card.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/ticket_list_section.dart';

import 'features/auth/data/login_mobile_contract_test.dart'
    show contractClient, reply;
import 'features/tickets/presentation/ticket_refresh_test.dart'
    show ticketResponse, refreshBloc, loadFirstPage;
import 'inspection_list_ui_test.dart' show inspectionResponse;

const _labels = ['Ord No. 011, Series of 2014', 'Ord No. 145, Series of 2006'];
const _summary = <String, Object?>{
  ...ticketResponse,
  'ordinance_names': _labels,
};

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('older ticket summary without ordinance names remains readable', () {
    expect(
      TicketSummaryModel.fromJson(ticketResponse).toEntity().ordinance,
      isEmpty,
    );
  });

  test('valid empty ticket response remains an empty success', () async {
    final client = contractClient(
      (options) async =>
          reply(options, {'items': <Object?>[], 'has_more': false}),
    );
    addTearDown(client.dio.close);
    final result = await TicketRepositoryImpl(
      TicketRemoteDataSourceImpl(client),
    ).loadTickets('', 0, TicketStatus.pending);
    expect(result, isA<Success<PageResult<TicketSummary>>>());
    expect((result as Success<PageResult<TicketSummary>>).data.items, isEmpty);
  });

  test('ticket server failure preserves its safe message', () async {
    final client = contractClient(
      (options) async => throw DioException(
        requestOptions: options,
        response: Response<Object?>(
          requestOptions: options,
          statusCode: 503,
          data: {'message': 'Tickets are temporarily unavailable.'},
        ),
        type: DioExceptionType.badResponse,
      ),
    );
    addTearDown(client.dio.close);
    final result = await TicketRepositoryImpl(
      TicketRemoteDataSourceImpl(client),
    ).loadTickets('', 0, TicketStatus.pending);
    expect(result, isA<ResultFailure>());
    expect(
      (result as ResultFailure).failure.message,
      'Tickets are temporarily unavailable.',
    );
  });

  test('regression private summary accepts null stall and overdue date', () {
    final summary = TicketSummaryModel.fromJson({
      ..._summary,
      'stall_number': null,
      'overdue_date': null,
    }).toEntity();
    expect(summary.stallNumber, isNull);
    expect(summary.overDueDate, isNull);
  });

  for (final card in ['inspection', 'ticket']) {
    testWidgets(
      'regression $card card displays complete ordinance labels at 280px',
      (tester) async {
        tester.view.physicalSize = const Size(280, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final widget = card == 'ticket'
            ? TicketCard(
                ticketSummary: TicketSummaryModel.fromJson(_summary).toEntity(),
              )
            : InspectionCard(
                ticketSummary: InspectionSummaryModel.fromJson({
                  ...inspectionResponse,
                  'ordinance_names': _labels,
                }).toEntity(),
              );
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: SingleChildScrollView(
                padding: AppTheme.ticketCardPadding,
                child: widget,
              ),
            ),
          ),
        );
        for (final label in _labels) {
          expect(find.text(label), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  final malformedPages = <String, Object?>{
    'wrong date type': {
      'items': [
        {..._summary, 'issued_at': 42},
      ],
      'has_more': false,
    },
    'invalid date': {
      'items': [
        {..._summary, 'issued_at': 'invalid'},
      ],
      'has_more': false,
    },
    'unknown status': {
      'items': [
        {..._summary, 'status': 'Unknown'},
      ],
      'has_more': false,
    },
    'invalid ordinance list': {
      'items': [
        {
          ..._summary,
          'ordinance_names': [42],
        },
      ],
      'has_more': false,
    },
    'null response': null,
  };
  for (final entry in malformedPages.entries) {
    test(
      'regression ${entry.key} returns a recoverable ticket failure',
      () async {
        final client = contractClient(
          (options) async => reply(options, entry.value),
        );
        addTearDown(client.dio.close);
        final result = await TicketRepositoryImpl(
          TicketRemoteDataSourceImpl(client),
        ).loadTickets('', 0, TicketStatus.pending);
        expect(result, isA<ResultFailure>());
      },
    );
  }

  testWidgets('private overdue card omits null location and missing due date', (
    tester,
  ) async {
    final summary = TicketSummaryModel.fromJson({
      ..._summary,
      'stall_number': null,
      'overdue_date': null,
      'status': 'Overdue',
    }).toEntity();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: TicketCard(ticketSummary: summary),
          ),
        ),
      ),
    );
    expect(find.text('Section A'), findsOneWidget);
    expect(find.textContaining('null'), findsNothing);
    expect(find.textContaining('Overdue:'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final phase in ['initial', 'refresh', 'pagination']) {
    test(
      'malformed $phase response stops progress and retry recovers',
      () async {
        var fail = phase == 'initial';
        final client = contractClient(
          (options) async => reply(options, {
            'items': [
              if (fail) {..._summary, 'issued_at': 'invalid'} else _summary,
            ],
            'has_more': true,
          }),
        );
        addTearDown(client.dio.close);
        final bloc = refreshBloc(client);
        addTearDown(bloc.close);
        if (phase != 'initial') await loadFirstPage(bloc);
        fail = true;
        final offset = phase == 'pagination' ? 1 : 0;
        final failed = bloc.stream.firstWhere(
          (state) =>
              state is TicketError ||
              state is TicketsLoaded && state.errorMessage != null,
        );
        bloc.add(LoadTicketSummary(offset: offset));
        final state = await failed.timeout(const Duration(seconds: 5));
        if (phase == 'initial') {
          expect(state, isA<TicketError>());
        } else {
          final loaded = state as TicketsLoaded;
          expect(loaded.ticketSummary, hasLength(1));
          expect(loaded.isLoadingMore, isFalse);
          expect(loaded.isRefreshing, isFalse);
          expect(loaded.isLoadMoreError, phase == 'pagination');
        }
        fail = false;
        final recovered = bloc.stream.firstWhere(
          (state) =>
              state is TicketsLoaded &&
              !state.isLoadingMore &&
              !state.isRefreshing &&
              state.errorMessage == null,
        );
        bloc.add(LoadTicketSummary(offset: offset));
        final ready =
            await recovered.timeout(const Duration(seconds: 5))
                as TicketsLoaded;
        expect(ready.ticketSummary, hasLength(phase == 'pagination' ? 2 : 1));
      },
    );
  }

  testWidgets('initial malformed response shows retry and then a ticket card', (
    tester,
  ) async {
    var fail = true;
    late final TicketBloc bloc;
    await tester.runAsync(() async {
      final client = contractClient(
        (options) async => reply(options, {
          'items': [
            if (fail) {..._summary, 'issued_at': 'invalid'} else _summary,
          ],
          'has_more': false,
        }),
      );
      addTearDown(client.dio.close);
      bloc = refreshBloc(client);
      addTearDown(bloc.close);
      final failed = bloc.stream.firstWhere((state) => state is TicketError);
      bloc.add(LoadTicketSummary());
      await failed.timeout(const Duration(seconds: 5));
    });
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                TicketListSection(onRetry: () => bloc.add(LoadTicketSummary())),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('Unable to load tickets'), findsOneWidget);
    fail = false;
    await tester.runAsync(() async {
      final ready = bloc.stream.firstWhere((state) => state is TicketsLoaded);
      await tester.tap(find.text('Try again'));
      await ready.timeout(const Duration(seconds: 5));
    });
    await tester.pump();
    expect(find.byType(TicketCard), findsOneWidget);
  });
}
