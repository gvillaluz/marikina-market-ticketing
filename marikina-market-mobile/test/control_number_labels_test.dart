import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/notification/data/models/notification_summary_model.dart';
import 'package:marikina_market_mobile/features/notification/presentation/widgets/notification_tile.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/inspection_summary_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_hive_model.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/inspection_card.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/person_history_sheet.dart';

import 'features/auth/data/login_mobile_contract_test.dart' show reply;
import 'inspection_list_ui_test.dart' show inspectionResponse, listBloc;
import 'inspection_preview_navigation_test.dart' show flush;
import 'notification_ui_test.dart' show notificationResponse;

// Control number = the number printed on the paper ticket ("000456" here).
// "TKT-2026-0042" is the app's own running number, which people no longer see.

Future<void> show(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

void expectNoOldLabels() {
  expect(find.textContaining('System control'), findsNothing);
  expect(find.textContaining('SYSTEM CONTROL'), findsNothing);
  expect(find.textContaining('Paper reference'), findsNothing);
  expect(find.textContaining('TKT-2026-0042'), findsNothing);
}

void main() {
  setUpAll(() {
    final adapter = OrdinanceHiveModelAdapter();
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
  });
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('inspection card shows the paper control number only', (
    tester,
  ) async {
    await show(
      tester,
      InspectionCard(
        ticketSummary: InspectionSummaryModel.fromJson({
          ...inspectionResponse,
          'paper_reference': '000456',
        }).toEntity(),
      ),
    );
    expect(find.text('Control number: 000456'), findsOneWidget);
    expectNoOldLabels();
  });

  testWidgets('inspection card for an old ticket without a paper number', (
    tester,
  ) async {
    await show(
      tester,
      InspectionCard(
        ticketSummary: InspectionSummaryModel.fromJson(
          inspectionResponse,
        ).toEntity(),
      ),
    );
    expect(
      find.text('Control number: Unavailable (legacy record)'),
      findsOneWidget,
    );
    expectNoOldLabels();
  });

  testWidgets('person history shows the paper control number only', (
    tester,
  ) async {
    final bloc = (await tester.runAsync(
      () => listBloc(
        (options) async => reply(options, {
          'items': [
            {
              'ticket_id': 42,
              'control_number': 'TKT-2026-0042',
              'paper_reference': '000456',
              'business_name': 'Market Goods',
              'enforcer_name': 'Test Enforcer',
              'paper_violator_name': 'Juan Dela Cruz',
              'issue_place': 'Fish aisle near F-014',
              'status': 'Pending',
              'penalty_type': 'CashFine',
              'issued_at': '2026-10-07T08:00:00Z',
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
            body: PersonHistorySheet(personId: 31, name: 'Juan Dela Cruz'),
          ),
        ),
      ),
    );
    await flush(tester);
    expect(find.textContaining('Control number: 000456'), findsOneWidget);
    expect(
      find.textContaining('Issue place: Fish aisle near F-014'),
      findsOneWidget,
    );
    expectNoOldLabels();
  });

  testWidgets('notification names the ticket by its control number', (
    tester,
  ) async {
    await show(
      tester,
      NotificationTile(
        notification: NotificationSummaryModel.fromJson({
          ...notificationResponse,
          'control_number': '000456',
        }).toEntity(),
        onRead: (_) {},
      ),
    );
    expect(
      find.text(
        'Ticket 000456 for Market Goods and General Merchandise is now Pending.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('notification for an old ticket without a number', (
    tester,
  ) async {
    await show(
      tester,
      NotificationTile(
        notification: NotificationSummaryModel.fromJson({
          ...notificationResponse,
          'control_number': null,
        }).toEntity(),
        onRead: (_) {},
      ),
    );
    expect(
      find.text(
        'A ticket for Market Goods and General Merchandise is now Pending.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('null'), findsNothing);
  });
}
