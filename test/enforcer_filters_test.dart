import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/data/data_sources/ticket_remote_data_source.dart';
import 'package:marikina_market_mobile/features/tickets/data/data_sources/inspection_remote_data_source.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/filter_row.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/ticket_filter_row.dart';
import 'features/auth/data/login_mobile_contract_test.dart'
    show contractClient, reply;
import 'features/tickets/presentation/ticket_refresh_test.dart'
    show refreshBloc, ticketResponse;
import 'inspection_list_ui_test.dart' show listBloc, inspectionResponse;
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/bloc/ticket_event.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/bloc/ticket_state.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_event.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_state.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('All and every explicit filter send the correct query', () async {
    final requests = <RequestOptions>[];
    final client = contractClient((options) async {
      requests.add(options);
      return reply(options, {'items': [], 'has_more': false});
    });
    addTearDown(client.dio.close);
    for (final type in <ViolationType?>[null, ...ViolationType.values]) {
      await InspectionRemoteDataSourceImpl(client).loadInspections('', 0, type);
      expect(requests.last.uri.queryParameters['type'], type?.value);
      expect(requests.last.uri.queryParameters.containsKey('search'), isFalse);
    }
    for (final status in <TicketStatus?>[null, ...TicketStatus.values]) {
      await TicketRemoteDataSourceImpl(client).loadTickets('', 0, status);
      expect(requests.last.uri.queryParameters['status'], status?.value);
    }
  });

  test(
    'ticket switching ignores old page, resets paging, preserves search and retries All',
    () async {
      final oldRequest = Completer<RequestOptions>();
      final oldResponse = Completer<Response<Object?>>();
      final requests = <RequestOptions>[];
      var fail = false;
      final client = contractClient((options) async {
        requests.add(options);
        if (requests.length == 1) {
          oldRequest.complete(options);
          return oldResponse.future;
        }
        if (fail) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          );
        }
        return reply(options, {
          'items': [
            {...ticketResponse, 'id': 84, 'status': 'Paid'},
          ],
          'has_more': true,
        });
      });
      addTearDown(client.dio.close);
      final bloc = refreshBloc(client);
      addTearDown(bloc.close);
      bloc.add(LoadTicketSummary());
      final old = await oldRequest.future;
      final ready = bloc.stream.firstWhere(
        (s) => s is TicketsLoaded && !s.isLoadingMore && !s.isRefreshing,
      );
      bloc.add(
        LoadTicketSummary(status: TicketStatus.paid, search: 'Market & Goods'),
      );
      await ready;
      expect(requests.last.uri.queryParameters, {
        'offset': '0',
        'status': 'Paid',
        'search': 'Market & Goods',
      });
      oldResponse.complete(
        reply(old, {
          'items': [ticketResponse],
          'has_more': true,
        }),
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect((bloc.state as TicketsLoaded).ticketSummary.single.ticketId, 84);
      final paged = bloc.stream.firstWhere(
        (s) => s is TicketsLoaded && s.ticketSummary.length == 2,
      );
      bloc.add(
        LoadTicketSummary(
          status: TicketStatus.paid,
          search: 'Market & Goods',
          offset: 1,
        ),
      );
      await paged;
      expect(requests.last.uri.queryParameters['offset'], '1');
      fail = true;
      final failed = bloc.stream.firstWhere((s) => s is TicketError);
      bloc.add(LoadTicketSummary(status: null, search: 'Market & Goods'));
      await failed;
      expect(requests.last.uri.queryParameters.containsKey('status'), isFalse);
      expect(requests.last.uri.queryParameters['offset'], '0');
      fail = false;
      final retried = bloc.stream.firstWhere((s) => s is TicketsLoaded);
      bloc.add(LoadTicketSummary(status: null, search: 'Market & Goods'));
      await retried;
      expect((bloc.state as TicketsLoaded).ticketSummary, hasLength(1));
    },
  );

  test(
    'inspection All default and switching ignore old pages and preserve search',
    () async {
      final oldRequest = Completer<RequestOptions>();
      final oldResponse = Completer<Response<Object?>>();
      final requests = <RequestOptions>[];
      var fail = false;
      final bloc = await listBloc((options) async {
        requests.add(options);
        if (requests.length == 1) {
          oldRequest.complete(options);
          return oldResponse.future;
        }
        if (fail) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          );
        }
        return reply(options, {
          'items': [
            {...inspectionResponse, 'id': 84},
          ],
          'has_more': true,
        });
      });
      bloc.add(LoadInspectionTickets());
      final old = await oldRequest.future;
      expect(old.uri.queryParameters.containsKey('type'), isFalse);
      final ready = bloc.stream.firstWhere(
        (s) =>
            s is InspectionTicketsLoaded && !s.isLoadingMore && !s.isRefreshing,
      );
      bloc.add(
        LoadInspectionTickets(
          type: ViolationType.ticket,
          search: 'Market & Goods',
        ),
      );
      await ready;
      expect(requests.last.uri.queryParameters, {
        'offset': '0',
        'type': 'Ticket',
        'search': 'Market & Goods',
      });
      oldResponse.complete(
        reply(old, {
          'items': [inspectionResponse],
          'has_more': true,
        }),
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(
        (bloc.state as InspectionTicketsLoaded).ticketSummary.single.ticketId,
        84,
      );
      final paged = bloc.stream.firstWhere(
        (s) => s is InspectionTicketsLoaded && s.ticketSummary.length == 2,
      );
      bloc.add(
        LoadInspectionTickets(
          type: ViolationType.ticket,
          search: 'Market & Goods',
          offset: 1,
        ),
      );
      await paged;
      expect(requests.last.uri.queryParameters['offset'], '1');
      fail = true;
      final failed = bloc.stream.firstWhere((s) => s is InspectionError);
      bloc.add(LoadInspectionTickets(search: 'Market & Goods'));
      await failed;
      expect(requests.last.uri.queryParameters.containsKey('type'), isFalse);
      expect(requests.last.uri.queryParameters['offset'], '0');
      fail = false;
      final retried = bloc.stream.firstWhere(
        (s) => s is InspectionTicketsLoaded,
      );
      bloc.add(LoadInspectionTickets(search: 'Market & Goods'));
      await retried;
      expect(
        (bloc.state as InspectionTicketsLoaded).ticketSummary,
        hasLength(1),
      );
    },
  );

  test(
    'filter requests safely encode search without changing filters',
    () async {
      const search = 'Juan & status=Paid #1 + Market';
      final client = contractClient((options) async {
        expect(options.uri.queryParameters['search'], search);
        expect(options.uri.queryParameters['offset'], '10');
        if (options.uri.path.endsWith('inspections')) {
          expect(options.uri.queryParameters['type'], 'Warning');
        } else {
          expect(options.uri.queryParameters['status'], 'Pending');
        }
        return reply(options, {'items': [], 'has_more': false});
      });
      addTearDown(client.dio.close);
      await TicketRemoteDataSourceImpl(
        client,
      ).loadTickets(search, 10, TicketStatus.pending);
      await InspectionRemoteDataSourceImpl(
        client,
      ).loadInspections(search, 10, ViolationType.warning);
    },
  );

  testWidgets('inspection filter has Records style options at 280px', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(280, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ViolationType? selected = ViolationType.warning;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: FilterRow(
            typeSelected: selected,
            onChange: (value) => selected = value,
          ),
        ),
      ),
    );
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Warnings'), findsOneWidget);
    expect(find.text('Tickets'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
    await tester.tap(find.text('Tickets'));
    expect(selected, ViolationType.ticket);
    await tester.tap(find.text('Warnings'));
    expect(selected, ViolationType.warning);
    await tester.tap(find.text('All'));
    expect(selected, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ticket dropdown includes All statuses and readable labels', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(280, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    TicketStatus? selected = TicketStatus.pending;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: TicketFilterRow(
            statusSelected: selected,
            onChange: (value) => selected = value,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Pending'));
    await tester.pumpAndSettle();
    expect(find.text('All statuses'), findsOneWidget);
    expect(find.text('In Progress'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
    await tester.tap(find.text('All statuses'));
    await tester.pumpAndSettle();
    expect(selected, isNull);
    expect(tester.takeException(), isNull);
  });
}
