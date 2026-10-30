import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/submit_community_service_log_params.dart';
import 'package:marikina_market_mobile/features/tickets/data/data_sources/ticket_remote_data_source.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/bloc/ticket_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/bloc/ticket_event.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/bloc/ticket_state.dart';

import '../../../records_feature_test.dart' show detailResponse;
import '../../auth/data/login_mobile_contract_test.dart'
    show contractClient, reply;
import 'ticket_refresh_test.dart' show refreshBloc;

const emptyProgress = <String, Object?>{
  'ticket_id': 101,
  'hours_required': 8,
  'hours_completed': 0,
  'hours_remaining': 8,
  'completion_percentage': 0,
  'entries': <Object?>[],
};

SubmitCommunityServiceLogParams serviceEntry() =>
    SubmitCommunityServiceLogParams(
      ticketId: 101,
      serviceDate: DateTime(2026, 10, 13),
      hoursWorked: 2,
      proofFile: File('assets/logo/org_logo.png'),
    );

Future<void> loadServiceTicket(TicketBloc bloc) async {
  final loaded = bloc.stream.firstWhere(
    (state) => state is TicketDetailLoaded && state.isSettlementLoaded,
  );
  bloc.add(LoadTicketDetail(101));
  await loaded.timeout(const Duration(seconds: 5));
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  for (final receipt in [false, true]) {
    test(
      'settlement submission ID survives uncertain save and data source recreation: $receipt',
      () async {
        final ids = <String?>[];
        final client = contractClient((options) async {
          ids.add(
            Map.fromEntries((options.data as FormData).fields)['submission_id'],
          );
          if (ids.length == 1) {
            throw DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
            );
          }
          return reply(
            options,
            receipt
                ? {
                    'ticket_id': 101,
                    'penalty_type': 'CashFine',
                    'proof_urls': <String>[],
                  }
                : emptyProgress,
          );
        });
        Future<void> submit(TicketRemoteDataSourceImpl source) async {
          if (receipt) {
            await source.submitTicketReceiptProof(
              101,
              File('assets/logo/org_logo.png'),
            );
          } else {
            await source.submitCommunityServiceLog(serviceEntry());
          }
        }

        await expectLater(
          submit(TicketRemoteDataSourceImpl(client)),
          throwsA(anything),
        );
        await submit(TicketRemoteDataSourceImpl(client));
        expect(
          ids.first,
          matches(
            RegExp(
              r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
            ),
          ),
        );
        expect(ids[1], ids[0]);
        await submit(TicketRemoteDataSourceImpl(client));
        expect(ids[2], isNot(ids[0]));
      },
    );
  }

  for (final (hours, remaining, percentage, status) in [
    (2, 6, 25, TicketStatus.inProgress),
    (8, 0, 100, TicketStatus.cleared),
  ]) {
    test(
      'saved service entry refreshes ${status.value} and blocks double submit',
      () async {
        var stored = false;
        var posts = 0;
        final requested = Completer<RequestOptions>();
        final pending = Completer<Response<Object?>>();
        final progress = {
          ...emptyProgress,
          'hours_completed': hours,
          'hours_remaining': remaining,
          'completion_percentage': percentage,
          'entries': [
            {
              'service_date': '2026-10-13T00:00:00Z',
              'hours_worked': hours,
              'proof_url': 'https://example.invalid/service.png',
            },
          ],
        };
        final client = contractClient((options) async {
          if (options.method == 'POST') {
            posts++;
            requested.complete(options);
            return pending.future;
          }
          return reply(
            options,
            options.path.endsWith('/community-service')
                ? (stored ? progress : emptyProgress)
                : {
                    ...detailResponse,
                    'penalty_type': 'CommunityService',
                    'community_service_hours': 8,
                    'status': stored ? status.value : 'Pending',
                  },
          );
        });
        addTearDown(client.dio.close);
        final bloc = refreshBloc(client);
        addTearDown(bloc.close);
        await loadServiceTicket(bloc);
        final saved = bloc.stream.firstWhere(
          (state) =>
              state is TicketDetailLoaded &&
              !state.isSubmittingSettlement &&
              state.communityServiceProgress?.hoursCompleted == hours,
        );
        final entry = SubmitCommunityServiceLogParams(
          ticketId: 101,
          serviceDate: DateTime(2026, 10, 13),
          hoursWorked: hours.toDouble(),
          proofFile: File('assets/logo/org_logo.png'),
        );
        bloc.add(SubmitCommunityServiceLog(entry));
        final request = await requested.future;
        expect(
          (bloc.state as TicketDetailLoaded).isSubmittingSettlement,
          isTrue,
        );
        bloc.add(SubmitCommunityServiceLog(entry));
        await Future<void>.delayed(Duration.zero);
        expect(posts, 1);
        stored = true;
        pending.complete(reply(request, progress));
        final result =
            await saved.timeout(const Duration(seconds: 5))
                as TicketDetailLoaded;
        expect(result.ticket.ticketStatus, status);
        expect(result.communityServiceProgress!.hoursRemaining, remaining);
        expect(
          result.communityServiceProgress!.completionPercentage,
          percentage,
        );
        expect(posts, 1);
      },
    );
  }

  test(
    'uncertain service save requires reload before another submission',
    () async {
      var stored = false;
      var posts = 0;
      final client = contractClient((options) async {
        if (options.method == 'POST') {
          posts++;
          stored = true;
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          );
        }
        return reply(
          options,
          options.path.endsWith('/community-service')
              ? {
                  ...emptyProgress,
                  if (stored) ...{
                    'hours_completed': 2,
                    'hours_remaining': 6,
                    'completion_percentage': 25,
                  },
                }
              : {
                  ...detailResponse,
                  'penalty_type': 'CommunityService',
                  'community_service_hours': 8,
                  'status': stored ? 'InProgress' : 'Pending',
                },
        );
      });
      addTearDown(client.dio.close);
      final bloc = refreshBloc(client);
      addTearDown(bloc.close);
      await loadServiceTicket(bloc);
      final failed = bloc.stream.firstWhere(
        (state) =>
            state is TicketDetailLoaded &&
            !state.isSubmittingSettlement &&
            state.settlementMessage != null,
      );
      bloc.add(SubmitCommunityServiceLog(serviceEntry()));
      final result = await failed as TicketDetailLoaded;
      expect(result.isSettlementLoaded, isFalse);
      bloc.add(SubmitCommunityServiceLog(serviceEntry()));
      await Future<void>.delayed(Duration.zero);
      expect(posts, 1);
      await loadServiceTicket(bloc);
      final reloaded = bloc.state as TicketDetailLoaded;
      expect(reloaded.ticket.ticketStatus, TicketStatus.inProgress);
      expect(reloaded.communityServiceProgress!.hoursCompleted, 2);
      expect(posts, 1);
    },
  );
}
