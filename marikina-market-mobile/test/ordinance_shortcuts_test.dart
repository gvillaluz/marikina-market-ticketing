import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_hive_model.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/bottom_sheets/select_ordinance_bottom_sheet.dart';

import 'features/auth/data/login_mobile_contract_test.dart' show reply;
import 'inspection_list_ui_test.dart' show listBloc;
import 'inspection_preview_navigation_test.dart' show flush;

// Slice A2a on the phone: ordinance shortcuts and title/section search.
// Synthetic ordinances; every expected order is worked out by hand.

Map<String, Object?> ordinance(
  int id,
  String section,
  String title, {
  bool warningEligible = true,
  bool active = true,
}) => {
  'id': id,
  'ordinance_no': '011',
  'series': '2014',
  'section': section,
  'title': title,
  'category': 'Sanitation',
  'created_at': '2026-10-07T08:00:00Z',
  'updated_at': '2026-10-07T08:00:00Z',
  'is_active': active,
  'severity': 'Minor',
  'warning_eligible': warningEligible,
  'penalty_tier_count': 1,
};

final ordinances = [
  ordinance(1, '12', 'Market Identification Card'),
  ordinance(2, '49', 'Prohibition of Certain Inadequate Attire'),
  ordinance(3, '16', 'Timbangan Bayan Requirement', warningEligible: false),
  ordinance(4, '59', 'Tricycle Ban'),
  ordinance(5, '78', 'Opposing a Market Officer', active: false),
];

/// For tests that open the ordinance picker but are not about shortcuts:
/// answers `/ordinance/shortcuts` with empty groups and passes everything else on.
Future<Response<Object?>> Function(RequestOptions) withNoShortcuts(
  Future<Response<Object?>> Function(RequestOptions) other,
) =>
    (options) async => options.path == '/ordinance/shortcuts'
    ? reply(options, const {
        'person_ordinance_ids': <int>[],
        'my_recent_ordinance_ids': <int>[],
        'most_violated_ordinance_ids': <int>[],
      })
    : other(options);

const personHeader = "This person's past violations";
const recentHeader = 'My recent';
const mostViolatedHeader = 'Most violated (last 30 days)';
const allHeader = 'All ordinances';

Future<InspectionBloc> shortcutsBloc(
  WidgetTester tester,
  List<RequestOptions> requests, {
  Map<String, Object?>? shortcuts,
}) async => (await tester.runAsync(
  () => listBloc((options) async {
    requests.add(options);
    if (options.path == '/ordinance') return reply(options, ordinances);
    if (shortcuts == null) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return reply(options, shortcuts);
  }),
))!;

Future<void> showSheet(
  WidgetTester tester,
  InspectionBloc bloc, {
  bool isWarning = false,
  int? personId,
}) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    BlocProvider<InspectionBloc>.value(
      value: bloc,
      child: MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(800, 3000),
            disableAnimations: true,
          ),
          child: Scaffold(
            body: SelectOrdinanceBottomSheet(
              isWarningTicket: isWarning,
              ordinances: const [],
              onChanged: (_) {},
              vendorId: 42,
              personId: personId,
            ),
          ),
        ),
      ),
    ),
  );
  await flush(tester);
}

double top(WidgetTester tester, String text) =>
    tester.getTopLeft(find.textContaining(text).first).dy;

void main() {
  setUpAll(() {
    final adapter = OrdinanceHiveModelAdapter();
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
  });
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets(
    'shows the three shortcut groups above the full list, in order, active only',
    (tester) async {
      final requests = <RequestOptions>[];
      final bloc = await shortcutsBloc(
        tester,
        requests,
        shortcuts: {
          'person_ordinance_ids': [2, 1],
          'my_recent_ordinance_ids': [3, 5],
          'most_violated_ordinance_ids': [4],
        },
      );
      await showSheet(tester, bloc, personId: 7);

      final asked = requests.singleWhere(
        (r) => r.path == '/ordinance/shortcuts',
      );
      expect(asked.queryParameters, {'person_id': 7});
      // Person: 2 (Attire) then 1 (Identification). My recent: 3 (Timbangan);
      // 5 is inactive, so it never shows. Most violated: 4 (Tricycle).
      final order = [
        personHeader,
        'Inadequate Attire',
        'Market Identification Card',
        recentHeader,
        'Timbangan Bayan',
        mostViolatedHeader,
        'Tricycle Ban',
        allHeader,
      ];
      for (var i = 1; i < order.length; i++) {
        expect(
          top(tester, order[i - 1]) < top(tester, order[i]),
          isTrue,
          reason: '${order[i - 1]} should be above ${order[i]}',
        );
      }
      expect(find.textContaining('Opposing a Market Officer'), findsNothing);
      // Each shortcut also stays in the full list below.
      expect(find.textContaining('Inadequate Attire'), findsNWidgets(2));
      expect(find.textContaining('Tricycle Ban'), findsNWidgets(2));
    },
  );

  testWidgets('without a person, no person group and no person_id is sent', (
    tester,
  ) async {
    final requests = <RequestOptions>[];
    final bloc = await shortcutsBloc(
      tester,
      requests,
      shortcuts: {
        'person_ordinance_ids': <int>[],
        'my_recent_ordinance_ids': [3],
        'most_violated_ordinance_ids': [4],
      },
    );
    await showSheet(tester, bloc);

    final asked = requests.singleWhere((r) => r.path == '/ordinance/shortcuts');
    expect(asked.queryParameters, isEmpty);
    expect(find.text(personHeader), findsNothing);
    expect(find.text(recentHeader), findsOneWidget);
    expect(find.text(mostViolatedHeader), findsOneWidget);
  });

  testWidgets('a warning leaves out shortcuts that cannot be warned', (
    tester,
  ) async {
    final bloc = await shortcutsBloc(
      tester,
      [],
      shortcuts: {
        'person_ordinance_ids': [2],
        'my_recent_ordinance_ids': [3],
        'most_violated_ordinance_ids': [4],
      },
    );
    await showSheet(tester, bloc, isWarning: true, personId: 7);

    // Ordinance 3 cannot be warned, so "My recent" has nothing left to show.
    expect(find.text(personHeader), findsOneWidget);
    expect(find.text(recentHeader), findsNothing);
    expect(find.text(mostViolatedHeader), findsOneWidget);
    expect(find.textContaining('Timbangan Bayan'), findsNothing);
  });

  testWidgets(
    'searching by title or section shows only the matches, without groups',
    (tester) async {
      final bloc = await shortcutsBloc(
        tester,
        [],
        shortcuts: {
          'person_ordinance_ids': [2],
          'my_recent_ordinance_ids': [3],
          'most_violated_ordinance_ids': [4],
        },
      );
      await showSheet(tester, bloc, personId: 7);

      expect(find.text('Search section, title or number'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'attire');
      await tester.pump();
      expect(find.textContaining('Inadequate Attire'), findsOneWidget);
      expect(find.textContaining('Tricycle Ban'), findsNothing);
      expect(find.text(personHeader), findsNothing);
      expect(find.text(allHeader), findsNothing);

      // "59" is only Tricycle Ban's section.
      await tester.enterText(find.byType(TextField), '59');
      await tester.pump();
      expect(find.textContaining('Tricycle Ban'), findsOneWidget);
      expect(find.textContaining('Inadequate Attire'), findsNothing);

      await tester.enterText(find.byType(TextField), 'MARKET identification');
      await tester.pump();
      expect(find.textContaining('Market Identification Card'), findsOneWidget);
      expect(find.textContaining('Timbangan Bayan'), findsNothing);
    },
  );

  testWidgets('when the shortcuts cannot load, the full list still works', (
    tester,
  ) async {
    final bloc = await shortcutsBloc(tester, []);
    await showSheet(tester, bloc, personId: 7);

    expect(find.text(personHeader), findsNothing);
    expect(find.text(recentHeader), findsNothing);
    expect(find.text(mostViolatedHeader), findsNothing);
    expect(find.textContaining('No internet'), findsNothing);
    for (final title in [
      'Market Identification Card',
      'Inadequate Attire',
      'Timbangan Bayan',
      'Tricycle Ban',
    ]) {
      expect(find.textContaining(title), findsOneWidget);
    }
  });
}
