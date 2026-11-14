import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/inspection_summary_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_hive_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ticket_detail_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ticket_summary_model.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ticket_detail_content_data.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/inspection_card.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/person_history_sheet.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/ticket_card.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/ticket_detail_content.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/violator_detail_section.dart';

import 'features/auth/data/login_mobile_contract_test.dart' show reply;
import 'inspection_list_ui_test.dart' show listBloc;
import 'inspection_preview_navigation_test.dart' show flush;

// Slice B1: a ticket or warning for an unregistered vendor has no business. The server sends the market
// section and the issue place, and leaves the business id, name, owner, type, account number, stall and
// business snapshot empty. Synthetic data only.

const _unregisteredInspection = <String, Object?>{
  'id': 51,
  'type': 'Ticket',
  'control_number': '5',
  'paper_reference': '000456',
  'paper_violator_name': 'Juan Cruz',
  'issue_place': 'Palengke gate 2',
  'vendor_id': null,
  'first_name': null,
  'last_name': null,
  'registered_owner_name': null,
  'business_name': null,
  'business_type': null,
  'business_account_number': null,
  'stall_number': null,
  'business_snapshot': null,
  'market_section_id': 3,
  'market_section_name': 'Meat and Poultry',
  'enforcer_id': 7,
  'status': 'Pending',
  'severity': 'Minor',
  'ordinance_names': ['Keep the stall clean.'],
  'issued_at': '2026-11-08T08:00:00Z',
  'updated_at': '2026-11-08T08:00:00Z',
  'overdue_date': null,
};

final _unregisteredWarning = <String, Object?>{
  ..._unregisteredInspection,
  'id': 52,
  'type': 'Warning',
  'control_number': 'WRN-0052',
  'paper_reference': null,
  'status': null,
  'severity': null,
  'person_full_name': 'Juan Cruz',
};

const _unregisteredTicketRow = <String, Object?>{
  'id': 51,
  'enforcer_id': 7,
  'vendor_id': null,
  'control_number': '5',
  'paper_reference': '000456',
  'issue_place': 'Palengke gate 2',
  'status': 'Pending',
  'business_name': null,
  'business_snapshot': null,
  'registered_owner_name': null,
  'stall_number': null,
  'market_section_name': 'Meat and Poultry',
  'issued_at': '2026-11-08T08:00:00Z',
  'updated_at': '2026-11-08T08:00:00Z',
  'overdue_date': null,
};

Map<String, Object?> _unregisteredDetail(String type) => {
  'ticket_id': 51,
  'enforcer_id': 7,
  'vendor_id': null,
  'type': type,
  'business_type': null,
  'business_account_number': null,
  'business_name': null,
  'first_name': null,
  'last_name': null,
  'registered_owner_name': null,
  'stall_number': null,
  'business_snapshot': null,
  'person_id': 31,
  'person_full_name': 'Juan Cruz',
  'paper_violator_name': 'Juan Cruz',
  'issue_place': 'Palengke gate 2',
  'violations': <Object?>[],
  'issued_at': '2026-11-08T08:00:00Z',
  'market_section_name': 'Meat and Poultry',
  'categories': <Object?>[],
  'description': 'Synthetic citation',
};

Future<void> _show(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

void _expectUnregisteredWording() {
  expect(find.text('Unregistered vendor'), findsOneWidget);
  expect(find.text('Historical business details unavailable.'), findsNothing);
}

void main() {
  setUpAll(() {
    final adapter = OrdinanceHiveModelAdapter();
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
  });
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('lists and the ticket page read a record with no business', () {
    final inspection = InspectionSummaryModel.fromJson(
      _unregisteredInspection,
    ).toEntity();
    final ticket = TicketSummaryModel.fromJson(
      _unregisteredTicketRow,
    ).toEntity();
    final detail = TicketDetailModel.fromJson(
      _unregisteredDetail('Ticket'),
    ).toEntity();

    expect(inspection.isUnregistered, isTrue);
    expect(ticket.isUnregistered, isTrue);
    expect(detail.isUnregistered, isTrue);
    expect(inspection.marketSection, 'Meat and Poultry');
    expect(ticket.marketSection, 'Meat and Poultry');
    expect(detail.marketSectionName, 'Meat and Poultry');
  });

  test('a record with a business is not unregistered', () {
    final inspection = InspectionSummaryModel.fromJson({
      ..._unregisteredInspection,
      'vendor_id': 12,
      'first_name': 'Maria',
      'last_name': 'Santos',
      'business_name': 'Market Goods',
      'business_type': 'Public',
      'business_account_number': 'BUS-12',
    }).toEntity();
    final ticket = TicketSummaryModel.fromJson({
      ..._unregisteredTicketRow,
      'vendor_id': 12,
      'business_name': 'Market Goods',
    }).toEntity();

    expect(inspection.isUnregistered, isFalse);
    expect(ticket.isUnregistered, isFalse);
  });

  for (final record in [_unregisteredInspection, _unregisteredWarning]) {
    final type = record['type'];
    testWidgets('inspection list card for an unregistered $type', (
      tester,
    ) async {
      await _show(
        tester,
        InspectionCard(
          ticketSummary: InspectionSummaryModel.fromJson(record).toEntity(),
          expanded: false,
          onToggle: () {},
        ),
      );
      _expectUnregisteredWording();
      expect(find.textContaining('Meat and Poultry'), findsOneWidget);
      expect(find.textContaining('Unavailable'), findsNothing);
    });
  }

  testWidgets('ticket list card for an unregistered ticket', (tester) async {
    await _show(
      tester,
      TicketCard(
        ticketSummary: TicketSummaryModel.fromJson(
          _unregisteredTicketRow,
        ).toEntity(),
        expanded: false,
        onToggle: () {},
      ),
    );
    _expectUnregisteredWording();
    expect(find.textContaining('Issue place'), findsNothing);
    expect(find.text('Meat and Poultry'), findsOneWidget);
  });

  for (final type in ['Ticket', 'Warning']) {
    testWidgets('ticket page violator details for an unregistered $type', (
      tester,
    ) async {
      final detail = TicketDetailModel.fromJson(
        _unregisteredDetail(type),
      ).toEntity();
      await _show(
        tester,
        ViolatorDetailSection(ticket: detail, isTicket: type == 'Ticket'),
      );
      _expectUnregisteredWording();
      expect(find.text('BUSINESS ID:'), findsNothing);
      expect(find.text('TRADE NAME:'), findsNothing);
      expect(find.text('REGISTERED OWNER:'), findsNothing);
      // A ticket names the recorded violator; a warning has no name line.
      expect(
        find.textContaining('Juan Cruz'),
        type == 'Ticket' ? findsWidgets : findsNothing,
      );
    });
  }

  testWidgets(
    'ticket page shows the market section of an unregistered ticket',
    (tester) async {
      tester.view.physicalSize = const Size(600, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final detail = TicketDetailModel.fromJson(
        _unregisteredDetail('Ticket'),
      ).toEntity();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: TicketDetailContent(
                data: TicketDetailContentData(
                  ticket: detail,
                  droppedOrdinances: null,
                  settlement: null,
                ),
                onSubmitReceipt: (_) {},
                onSubmitCommunityServiceLog: (_) {},
                onRetrySettlementLoad: () {},
              ),
            ),
          ),
        ),
      );
      expect(find.text('Meat and Poultry'), findsOneWidget);
      expect(find.text('Palengke gate 2'), findsOneWidget);
      expect(
        find.text('Historical business details unavailable.'),
        findsNothing,
      );
    },
  );

  testWidgets('person history names an unregistered vendor', (tester) async {
    final bloc = (await tester.runAsync(
      () => listBloc(
        (options) async => reply(options, {
          'items': [
            {
              'ticket_id': 51,
              'paper_reference': '000456',
              'business_name': null,
              'business_snapshot': null,
              'enforcer_name': 'Test Enforcer',
              'paper_violator_name': 'Juan Cruz',
              'issue_place': 'Palengke gate 2',
              'status': 'Pending',
              'penalty_type': 'CashFine',
              'issued_at': '2026-11-08T08:00:00Z',
              'assessed_cash_fine': 500,
              'outstanding_cash_fine': 500,
              'ordinances': ['011 2014'],
            },
          ],
          'has_more': false,
          'total': 1,
        }),
      ),
    ))!;
    await tester.pumpWidget(
      BlocProvider<InspectionBloc>.value(
        value: bloc,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: PersonHistorySheet(personId: 31, name: 'Juan Cruz'),
          ),
        ),
      ),
    );
    await flush(tester);
    expect(find.text('000456'), findsOneWidget);
    expect(find.text('Unregistered vendor'), findsOneWidget);
    expect(find.textContaining('Historical business details'), findsNothing);
  });
}
