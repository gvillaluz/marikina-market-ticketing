import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_hive_model.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/person_history_sheet.dart';

import 'features/auth/data/login_mobile_contract_test.dart' show reply;
import 'inspection_list_ui_test.dart' show listBloc;
import 'inspection_preview_navigation_test.dart' show flush;

Map<String, Object?> row(int id, String status, {double? assessed = 500}) => {
  'ticket_id': id,
  'paper_reference': '00045$id',
  'business_name': 'Market Goods',
  'enforcer_name': 'Test Enforcer',
  'paper_violator_name': 'Juan Dela Cruz',
  'issue_place': 'Fish aisle near F-014',
  'status': status,
  'penalty_type': 'CashFine',
  'issued_at': '2026-10-07T08:00:00Z',
  'assessed_cash_fine': assessed,
  'outstanding_cash_fine': status == 'Paid' ? 0 : 1500.5,
  'ordinances': ['011 2014'],
};

Future<void> showSheet(
  WidgetTester tester,
  InspectionBloc bloc, {
  Size size = const Size(390, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
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
}

void main() {
  setUpAll(() {
    final adapter = OrdinanceHiveModelAdapter();
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
  });
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('a citation card shows number, status, place and amounts', (
    tester,
  ) async {
    final bloc = (await tester.runAsync(
      () => listBloc(
        (options) async => reply(options, {
          'items': [row(1, 'Pending'), row(2, 'Paid', assessed: null)],
          'has_more': false,
          'total': 2,
        }),
      ),
    ))!;
    await showSheet(tester, bloc);
    expect(find.text('Juan Dela Cruz'), findsWidgets);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);
    expect(find.text('Control number'), findsNWidgets(2));
    expect(find.text('Fish aisle near F-014'), findsNWidgets(2));
    expect(find.text('₱500.00'), findsOneWidget);
    expect(find.text('Not cash'), findsOneWidget);
    expect(find.text('₱1,500.50'), findsOneWidget);
    expect(find.text('₱0.00'), findsOneWidget);
    expect(find.text('Load more'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a person with no citations sees an empty message', (
    tester,
  ) async {
    final bloc = (await tester.runAsync(
      () => listBloc(
        (options) async =>
            reply(options, {'items': [], 'has_more': false, 'total': 0}),
      ),
    ))!;
    await showSheet(tester, bloc);
    expect(find.text('No citations yet'), findsOneWidget);
    expect(find.text('No citations linked to this person.'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('an error shows the message and Retry loads the history', (
    tester,
  ) async {
    var calls = 0;
    final bloc = (await tester.runAsync(
      () => listBloc((options) async {
        if (++calls == 1) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response<Object?>(
              requestOptions: options,
              statusCode: 500,
              data: {'message': 'History is unavailable.'},
            ),
          );
        }
        return reply(options, {
          'items': [row(1, 'Pending')],
          'has_more': false,
          'total': 1,
        });
      }),
    ))!;
    await showSheet(tester, bloc);
    expect(find.text('History is unavailable.'), findsOneWidget);
    expect(find.text('Could not load the history'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await flush(tester);
    expect(calls, 2);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('Load more adds the next page below the first', (tester) async {
    final offsets = <Object?>[];
    final bloc = (await tester.runAsync(
      () => listBloc((options) async {
        offsets.add(options.queryParameters['offset']);
        final first = offsets.length == 1;
        return reply(options, {
          'items': [row(first ? 1 : 2, first ? 'Pending' : 'Waived')],
          'has_more': first,
          'total': 2,
        });
      }),
    ))!;
    await showSheet(tester, bloc);
    expect(find.text('Pending'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pump();
    await tester.tap(find.text('Load more'));
    await flush(tester);
    expect(offsets, [0, 1]);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Waived'), findsOneWidget);
    expect(find.text('Load more'), findsNothing);
  });

  testWidgets('fits a narrow phone at large text without overflow', (
    tester,
  ) async {
    final bloc = (await tester.runAsync(
      () => listBloc(
        (options) async => reply(options, {
          'items': [row(1, 'Contested')],
          'has_more': false,
          'total': 1,
        }),
      ),
    ))!;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await showSheet(tester, bloc, size: const Size(320, 640));
    expect(find.text('Contested'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
