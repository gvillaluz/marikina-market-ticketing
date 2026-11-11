import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_hive_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/person_candidate_model.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/person_candidate.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_event.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_state.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/bottom_sheets/business_result_card.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/bottom_sheets/search_business_bottom_sheet.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/violator_info_card.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/person_identity_review.dart';

import 'features/auth/data/login_mobile_contract_test.dart' show reply;
import 'inspection_list_ui_test.dart' show listBloc;
import 'inspection_preview_navigation_test.dart' show flush, vendor;

// Slice A1 on the phone: business search, the business people list and
// "Add helper". Synthetic people; expected texts are worked out by hand.

Map<String, Object?> totals({
  int offenses = 0,
  int warnings = 0,
  num unpaid = 0,
  String? lastAt,
  String? lastBusiness,
  List<String> businesses = const [],
}) => {
  'offense_count': offenses,
  'warning_count': warnings,
  'outstanding_fine': unpaid,
  'last_ticket_at': lastAt,
  'last_business_name': lastBusiness,
  'business_names': businesses,
};

Map<String, Object?> person(int id, String name, Map<String, Object?> t) => {
  'id': id,
  'full_name': name,
  'address': '$id Shoe Ave',
  'phone_number': null,
  'created_at': '2026-10-01T00:00:00Z',
  'ticket_totals': t,
};

// Juan: cited at Store X (paid) and Store 12 (₱500 pending), last on Oct 5.
final juan = person(
  1,
  'Juan Dela Cruz',
  totals(
    offenses: 2,
    unpaid: 500,
    lastAt: '2026-10-05T08:00:00Z',
    lastBusiness: 'Synthetic Market Goods',
    businesses: ['Store X', 'Synthetic Market Goods'],
  ),
);

// Pedro: only ticketed at Store X, so he is not on this business's list.
final pedro = person(
  3,
  'Pedro Reyes',
  totals(
    offenses: 1,
    warnings: 1,
    lastAt: '2026-10-02T08:00:00Z',
    lastBusiness: 'Store X',
    businesses: ['Store X'],
  ),
);

Future<void> showReview(
  WidgetTester tester,
  InspectionBloc bloc,
  void Function(PersonCandidate?, String) onChanged,
) async {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    BlocProvider.value(
      value: bloc,
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: PersonIdentityReview(vendor: vendor, onChanged: onChanged),
          ),
        ),
      ),
    ),
  );
  await flush(tester);
}

String nameField(WidgetTester tester) => tester
    .widget<TextField>(
      find.byWidgetPredicate(
        (w) =>
            w is TextField && w.decoration?.labelText == 'Paper violator name',
      ),
    )
    .controller!
    .text;

void main() {
  setUpAll(() {
    final adapter = OrdinanceHiveModelAdapter();
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
  });
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('person records carry ticket totals across businesses', () {
    final entity = PersonCandidateModel.fromJson(juan).toEntity();
    expect(entity.ticketTotals.offenseCount, 2);
    expect(entity.ticketTotals.warningCount, 0);
    expect(entity.ticketTotals.outstandingFine, 500);
    expect(entity.ticketTotals.lastTicketAt, DateTime.utc(2026, 10, 5, 8));
    expect(entity.ticketTotals.lastBusinessName, 'Synthetic Market Goods');
    expect(entity.ticketTotals.businessNames, [
      'Store X',
      'Synthetic Market Goods',
    ]);
    // A person just created has no ticket totals in the response.
    final created = PersonCandidateModel.fromJson({
      'id': 9,
      'full_name': 'New Helper',
      'address': '9 Shoe Ave',
    }).toEntity();
    expect(created.ticketTotals.offenseCount, 0);
    expect(created.ticketTotals.lastTicketAt, isNull);
  });

  test(
    'business search asks the lookup route and reports more results',
    () async {
      late RequestOptions sent;
      final bloc = await listBloc((options) async {
        sent = options;
        return reply(options, {
          'items': [
            {
              'vendor_id': 1,
              'username': null,
              'type': 'Public',
              'business_account_number': 'ACC-100',
              'stall_number': '12',
              'trade_name': "Aling Nena's Store",
              'last_name': 'Santos',
              'first_name': 'Nena',
              'middle_name': null,
              'address': '1 Market Lane',
              'market_section_id': 1,
              'market_section_name': 'Dry Goods',
            },
          ],
          'has_more': true,
          'total': 21,
        });
      });
      final loaded = bloc.stream.firstWhere((s) => s is InspectionSearchList);
      bloc.add(BusinessSearchRequested(' nena '));
      final state = await loaded as InspectionSearchList;
      expect(sent.path, '/vendor/lookup');
      expect(sent.queryParameters['search'], 'nena');
      expect(state.vendorList.single.tradeName, "Aling Nena's Store");
      expect(state.hasMore, isTrue);
    },
  );

  Map<String, Object?> vendorJson(int id, String name, String? stall) => {
    'vendor_id': id,
    'username': null,
    'type': 'Public',
    'business_account_number': 'ACC-$id',
    'stall_number': stall,
    'trade_name': name,
    'last_name': 'Santos',
    'first_name': 'Nena',
    'middle_name': null,
    'address': '12, Shoe Ave, Sto. Niño, Marikina City',
    'market_section_id': 1,
    'market_section_name': 'Dry Goods',
  };

  Future<void> showBusinessSheet(
    WidgetTester tester,
    List<Map<String, Object?>> items, {
    required bool hasMore,
  }) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final bloc = await tester.runAsync(
      () => listBloc(
        (options) async => reply(options, {
          'items': items,
          'has_more': hasMore,
          'total': hasMore ? 21 : items.length,
        }),
      ),
    );
    await tester.pumpWidget(
      BlocProvider<InspectionBloc>.value(
        value: bloc!,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(body: SearchBusinessBottomSheet()),
          ),
        ),
      ),
    );
  }

  Future<void> typeInBusinessSheet(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump(AppTheme.inspectionSearchDelay);
    await flush(tester);
  }

  testWidgets(
    'business sheet has a short prompt, then shows a card per business and asks to keep typing',
    (tester) async {
      await showBusinessSheet(tester, [
        vendorJson(1, "Aling Nena's Store", '12'),
      ], hasMore: true);
      expect(find.text('Search businesses'), findsOneWidget);
      expect(
        find.text('Search, then tap a business to select it.'),
        findsOneWidget,
      );
      expect(find.text('Start typing to find a business.'), findsOneWidget);
      expect(find.text('1 business shown'), findsNothing);
      await typeInBusinessSheet(tester, 'santos');
      expect(find.text("Aling Nena's Store"), findsOneWidget);
      expect(find.text('Stall 12'), findsOneWidget);
      expect(find.text('Dry Goods'), findsOneWidget);
      expect(find.text('Public'), findsOneWidget);
      expect(find.text('Nena Santos'), findsOneWidget);
      expect(
        find.text('12, Shoe Ave, Sto. Niño, Marikina City'),
        findsOneWidget,
      );
      expect(find.text('Account ACC-1'), findsOneWidget);
      expect(find.text('1 business shown'), findsOneWidget);
      expect(find.text('Keep typing to narrow the results.'), findsOneWidget);
    },
  );

  testWidgets('business sheet counts the results when there are no more', (
    tester,
  ) async {
    await showBusinessSheet(tester, [
      vendorJson(1, "Aling Nena's Store", '12'),
      vendorJson(2, 'Santos Fresh Fish', null),
    ], hasMore: false);
    await typeInBusinessSheet(tester, 'santos');
    expect(find.text('2 businesses found'), findsOneWidget);
    expect(find.text('Keep typing to narrow the results.'), findsNothing);
  });

  testWidgets('tapping a business card enables Select business', (
    tester,
  ) async {
    await showBusinessSheet(tester, [
      vendorJson(1, "Aling Nena's Store", '12'),
    ], hasMore: false);
    await typeInBusinessSheet(tester, 'nena');
    ElevatedButton button() =>
        tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button().onPressed, isNull);
    await tester.tap(find.byType(BusinessResultCard));
    await tester.pump();
    expect(button().onPressed, isNotNull);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('entry page business card names every way to search', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ViolatorInfoCard(
            isUnregistered: false,
            onKindChanged: (_) {},
            onVendorSelected: (_) {},
            onSectionSelected: (_) {},
            errorMessage: null,
          ),
        ),
      ),
    );
    expect(find.text('Search for a registered business.'), findsOneWidget);
  });

  testWidgets(
    'people list shows the owner and people ticketed here with totals; one tap selects',
    (tester) async {
      final paths = <String>[];
      final bloc = await tester.runAsync(
        () => listBloc((options) async {
          paths.add(options.path);
          return reply(options, [juan]);
        }),
      );
      PersonCandidate? selected;
      var paperName = '';
      await showReview(tester, bloc!, (p, name) {
        selected = p;
        paperName = name;
      });
      expect(paths, ['/vendor/12/people']);
      expect(find.text('Owner: Synthetic Vendor'), findsOneWidget);
      expect(find.text('Juan Dela Cruz'), findsOneWidget);
      expect(
        find.text('2 offenses · 0 warnings · ₱500.00 unpaid'),
        findsOneWidget,
      );
      expect(
        find.text('Last ticket: Oct 5, 2026 at Synthetic Market Goods'),
        findsOneWidget,
      );
      await tester.tap(find.text('Select'));
      await tester.pump();
      expect(selected?.id, 1);
      expect(paperName, 'Juan Dela Cruz');
      expect(nameField(tester), 'Juan Dela Cruz');
    },
  );

  testWidgets('people list explains when nobody was ticketed here yet', (
    tester,
  ) async {
    final bloc = await tester.runAsync(
      () => listBloc((options) async => reply(options, [])),
    );
    await showReview(tester, bloc!, (_, _) {});
    expect(
      find.text('No one has been ticketed at this business yet.'),
      findsOneWidget,
    );
    expect(find.text('Owner: Synthetic Vendor'), findsOneWidget);
  });

  testWidgets('people list shows a plain error and retry loads it again', (
    tester,
  ) async {
    var calls = 0;
    final bloc = await tester.runAsync(
      () => listBloc((options) async {
        calls++;
        if (calls == 1) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          );
        }
        return reply(options, [juan]);
      }),
    );
    await showReview(tester, bloc!, (_, _) {});
    expect(
      find.text('No internet connection. Please try again.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Retry'));
    await flush(tester);
    expect(calls, 2);
    expect(find.text('Juan Dela Cruz'), findsOneWidget);
  });

  testWidgets(
    'tapping the owner searches people with the owner name filled in',
    (tester) async {
      final requests = <RequestOptions>[];
      final bloc = await tester.runAsync(
        () => listBloc((options) async {
          requests.add(options);
          if (options.path == '/persons/matches') {
            return reply(options, {'items': [], 'has_more': false});
          }
          return reply(options, []);
        }),
      );
      await showReview(tester, bloc!, (_, _) {});
      await tester.tap(find.text('Find owner'));
      await flush(tester);
      expect(nameField(tester), 'Synthetic Vendor');
      expect(requests.last.path, '/persons/matches');
      expect(requests.last.data['name'], 'Synthetic Vendor');
    },
  );

  testWidgets('new person is the main choice only when nobody matches', (
    tester,
  ) async {
    var matches = <Object?>[
      {
        ...pedro,
        'matched_fields': ['name'],
      },
    ];
    final bloc = await tester.runAsync(
      () => listBloc((options) async {
        if (options.path == '/persons/matches') {
          return reply(options, {'items': matches, 'has_more': false});
        }
        return reply(options, []);
      }),
    );
    await showReview(tester, bloc!, (_, _) {});
    final name = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == 'Paper violator name',
    );
    expect(find.text('New person'), findsNothing);
    await tester.enterText(name, 'pedro');
    await tester.tap(find.text('Check possible matches'));
    await flush(tester);
    // A same-name stranger can still be recorded, but only after the matches.
    expect(find.text('New person'), findsNothing);
    expect(find.text('Not any of these – new person'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Not any of these – new person')).dy,
      greaterThan(tester.getTopLeft(find.text('Pedro Reyes')).dy),
    );

    matches = [];
    await tester.enterText(name, 'nobody');
    await tester.tap(find.text('Check possible matches'));
    await flush(tester);
    expect(find.text('New person'), findsOneWidget);
    expect(find.text('Not any of these – new person'), findsNothing);
  });

  testWidgets(
    'add helper finds a person from another business and selects without retyping',
    (tester) async {
      final bloc = await tester.runAsync(
        () => listBloc((options) async {
          if (options.path == '/persons/matches') {
            return reply(options, {
              'items': [
                {
                  ...pedro,
                  'matched_fields': ['name'],
                },
              ],
              'has_more': false,
            });
          }
          return reply(options, [juan]);
        }),
      );
      PersonCandidate? selected;
      var paperName = '';
      await showReview(tester, bloc!, (p, name) {
        selected = p;
        paperName = name;
      });
      expect(find.text('Pedro Reyes'), findsNothing);
      await tester.enterText(
        find.byWidgetPredicate(
          (w) =>
              w is TextField &&
              w.decoration?.labelText == 'Paper violator name',
        ),
        'pedro',
      );
      await tester.tap(find.text('Check possible matches'));
      await flush(tester);
      expect(find.text('Pedro Reyes'), findsOneWidget);
      expect(find.text('1 offense · 1 warning · ₱0.00 unpaid'), findsOneWidget);
      expect(find.text('Ticketed at: Store X'), findsOneWidget);
      await tester.tap(find.text('Same person – select'));
      await tester.pump();
      expect(selected?.id, 3);
      expect(paperName, 'Pedro Reyes');
      expect(nameField(tester), 'Pedro Reyes');
    },
  );
}
