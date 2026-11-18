import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/page_result.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/data/data_sources/ticket_remote_data_source.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ticket_summary_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/repositories/ticket_repository_impl.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ticket_summary.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/ticket_card.dart';

import 'features/auth/data/login_mobile_contract_test.dart'
    show contractClient, reply;
import 'features/tickets/presentation/ticket_refresh_test.dart'
    show ticketResponse;

// Phase 4 line 3 finding: a ticket loaded outside the app (here, the server's answer for made-up demo
// ticket 30 in the test database) has no hidden running number. The list never shows that number, so
// one such ticket must not stop the enforcer's whole Tickets list from loading.
const _noHiddenNumber = <String, Object?>{
  'business_snapshot': null,
  'paper_reference': 'RA-DEMO-06',
  'issue_place': null,
  'id': 30,
  'enforcer_id': 1,
  'vendor_id': null,
  'person_id': 2,
  'person_full_name': 'Maria Santos',
  'paper_violator_name': null,
  'registered_owner_name': null,
  'control_number': null,
  'status': 'Pending',
  'business_name': null,
  'business_type': null,
  'business_account_number': null,
  'stall_number': null,
  'ordinance_names': <String>[],
  'market_section_name': 'J. P. Rizal Street',
  'issued_at': '2026-11-13T22:30:00Z',
  'updated_at': '2026-11-13T22:30:00Z',
  'overdue_date': '2026-11-18T22:30:00Z',
};

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('a ticket without a hidden number is read', () {
    final summary = TicketSummaryModel.fromJson(_noHiddenNumber).toEntity();
    expect(summary.ticketId, 30);
    expect(summary.paperReference, 'RA-DEMO-06');
  });

  test(
    'the Tickets list loads with one such ticket among normal ones',
    () async {
      final client = contractClient(
        (options) async => reply(options, {
          'items': [ticketResponse, _noHiddenNumber],
          'has_more': false,
          'total': 2,
        }),
      );
      addTearDown(client.dio.close);

      final result = await TicketRepositoryImpl(
        TicketRemoteDataSourceImpl(client),
      ).loadTickets('', 0, TicketStatus.pending);

      expect(result, isA<Success<PageResult<TicketSummary>>>());
      final items = (result as Success<PageResult<TicketSummary>>).data.items;
      expect(items.map((t) => t.ticketId), [42, 30]);
    },
  );

  testWidgets('its card shows the paper control number', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: TicketCard(
              ticketSummary: TicketSummaryModel.fromJson(
                _noHiddenNumber,
              ).toEntity(),
              expanded: false,
              onToggle: () {},
            ),
          ),
        ),
      ),
    );
    expect(find.text('RA-DEMO-06'), findsOneWidget);
  });
}
