import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/network/client.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/skeleton_box.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/data/data_sources/ticket_remote_data_source.dart';
import 'package:marikina_market_mobile/features/tickets/data/repositories/ticket_repository_impl.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/load_community_service_progress_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/load_ticket_detail_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/load_ticket_list_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/load_ticket_receipt_proof_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/submit_community_service_log_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/submit_ticket_receipt_proof_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/bloc/ticket_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/bloc/ticket_event.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/bloc/ticket_state.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/pages/tickets_page.dart';

import '../../auth/data/login_mobile_contract_test.dart'
    show contractClient, reply;

const ticketResponse = <String, Object?>{
  'id': 42,
  'enforcer_id': 7,
  'vendor_id': 12,
  'control_number': 'TKT-2026-0042',
  'status': 'Pending',
  'business_name': 'Market Goods',
  'stall_number': 'A-12',
  'market_section_name': 'Section A',
  'issued_at': '2026-10-07T08:00:00Z',
  'updated_at': '2026-10-07T08:00:00Z',
  'overdue_date': '2026-10-12T08:00:00Z',
};

TicketBloc refreshBloc(ApiClient client) {
  final repository = TicketRepositoryImpl(TicketRemoteDataSourceImpl(client));
  return TicketBloc(
    loadTicketListUseCase: LoadTicketListUseCase(repository),
    loadTicketDetailUseCase: LoadTicketDetailUseCase(repository),
    loadTicketReceiptProofUseCase: LoadTicketReceiptProofUseCase(repository),
    loadCommunityServiceProgressUseCase: LoadCommunityServiceProgressUseCase(
      repository,
    ),
    submitTicketReceiptProofUseCase: SubmitTicketReceiptProofUseCase(
      repository,
    ),
    submitCommunityServiceLogUseCase: SubmitCommunityServiceLogUseCase(
      repository,
    ),
  );
}

Future<void> loadFirstPage(TicketBloc bloc) async {
  final loaded = bloc.stream.firstWhere((state) => state is TicketsLoaded);
  bloc.add(LoadTicketSummary());
  await loaded;
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  for (final empty in [false, true]) {
    testWidgets(
      'refresh keeps ${empty ? 'empty state at 320px' : 'tickets'} visible',
      (tester) async {
        if (empty) {
          tester.view.physicalSize = const Size(320, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
        }
        var requests = 0;
        final requested = Completer<RequestOptions>();
        final response = Completer<Response<Object?>>();
        final client = contractClient((options) async {
          requests++;
          if (requests == 1) {
            return reply(options, {
              'items': [if (!empty) ticketResponse],
              'has_more': false,
            });
          }
          requested.complete(options);
          return response.future;
        });
        addTearDown(client.dio.close);
        final bloc = refreshBloc(client);
        addTearDown(bloc.close);
        addTearDown(() {
          if (!response.isCompleted) {
            response.complete(
              reply(RequestOptions(path: '/enforcer/tickets'), {
                'items': [],
                'has_more': false,
              }),
            );
          }
        });
        await tester.runAsync(() => loadFirstPage(bloc));
        await tester.pumpWidget(
          BlocProvider.value(
            value: bloc,
            child: MaterialApp(
              theme: AppTheme.light,
              home: const Scaffold(body: TicketsPage()),
            ),
          ),
        );
        var finished = false;
        final refresh = tester
            .widget<RefreshIndicator>(find.byType(RefreshIndicator))
            .onRefresh()
            .then((_) => finished = true);
        final options = await tester.runAsync(() => requested.future);
        await tester.pump();
        expect(bloc.state, isA<TicketsLoaded>());
        expect((bloc.state as TicketsLoaded).isRefreshing, isTrue);
        expect(find.byType(SkeletonBox), findsNothing);
        expect(
          find.text(empty ? 'No Tickets Found' : '#TKT-2026-0042'),
          findsOneWidget,
        );
        expect(finished, isFalse);
        await tester.runAsync(() async {
          response.complete(
            reply(options!, {
              'items': [
                if (!empty)
                  {...ticketResponse, 'business_name': 'Updated Market Goods'},
              ],
              'has_more': false,
            }),
          );
          await refresh;
        });
        await tester.pump();
        expect(finished, isTrue);
        expect((bloc.state as TicketsLoaded).isRefreshing, isFalse);
        expect(
          find.text(empty ? 'No Tickets Found' : 'Updated Market Goods'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  test(
    'initial load uses skeleton state and pagination is blocked during refresh',
    () async {
      final firstRequest = Completer<RequestOptions>();
      final firstResponse = Completer<Response<Object?>>();
      final refreshRequest = Completer<RequestOptions>();
      final refreshResponse = Completer<Response<Object?>>();
      var requests = 0;
      final client = contractClient((options) async {
        requests++;
        if (requests == 1) {
          firstRequest.complete(options);
          return firstResponse.future;
        }
        if (requests == 2) {
          refreshRequest.complete(options);
          return refreshResponse.future;
        }
        return reply(options, {'items': [], 'has_more': false});
      });
      addTearDown(client.dio.close);
      final bloc = refreshBloc(client);
      addTearDown(bloc.close);
      addTearDown(() {
        for (final pending in [firstResponse, refreshResponse]) {
          if (!pending.isCompleted) {
            pending.complete(
              reply(RequestOptions(path: '/enforcer/tickets'), {
                'items': [],
                'has_more': false,
              }),
            );
          }
        }
      });
      final ready = bloc.stream.firstWhere((state) => state is TicketsLoaded);
      bloc.add(LoadTicketSummary());
      final firstOptions = await firstRequest.future;
      expect(bloc.state, isA<TicketLoading>());
      firstResponse.complete(
        reply(firstOptions, {
          'items': [ticketResponse],
          'has_more': true,
        }),
      );
      await ready;
      bloc.add(LoadTicketSummary());
      final options = await refreshRequest.future;
      bloc.add(LoadTicketSummary(offset: 1));
      await Future<void>.delayed(Duration.zero);
      expect(requests, 2);
      expect((bloc.state as TicketsLoaded).isLoadingMore, isFalse);
      final finished = bloc.stream.firstWhere(
        (state) => state is TicketsLoaded && !state.isRefreshing,
      );
      refreshResponse.complete(
        reply(options, {'items': [], 'has_more': false}),
      );
      await finished;
    },
  );

  test(
    'failed refresh retains existing tickets and stops refreshing',
    () async {
      var requests = 0;
      final client = contractClient((options) async {
        if (++requests == 1) {
          return reply(options, {
            'items': [ticketResponse],
            'has_more': false,
          });
        }
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      });
      addTearDown(client.dio.close);
      final bloc = refreshBloc(client);
      addTearDown(bloc.close);
      await loadFirstPage(bloc);
      final failed = bloc.stream.firstWhere(
        (state) => state is TicketsLoaded && state.errorMessage != null,
      );
      bloc.add(LoadTicketSummary());
      final state = await failed as TicketsLoaded;
      expect(state.ticketSummary.single.ticketId, 42);
      expect(state.isRefreshing, isFalse);
      expect(state.isLoadingMore, isFalse);
    },
  );
}
