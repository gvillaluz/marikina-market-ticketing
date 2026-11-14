import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/app_primary_btn.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_hive_model.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/person_candidate.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/vendor_summary.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/business_type.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_event.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_state.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/create_person_sheet.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/find_person_sheet.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/person_history_sheet.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/person_identity_review.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/person_result_card.dart';

import 'features/auth/data/login_mobile_contract_test.dart' show reply;
import 'inspection_list_ui_test.dart' show listBloc;
import 'inspection_preview_navigation_test.dart' show flush, vendor;

// Choosing the violator on the entry page: the owner card first, then
// "Helper" (or "Find violator" without a business) opens a name search.
// Synthetic people; expected texts are worked out by hand.

Map<String, Object?> totals({
  int offenses = 0,
  int warnings = 0,
  num unpaid = 0,
}) => {
  'offense_count': offenses,
  'warning_count': warnings,
  'outstanding_fine': unpaid,
  'last_ticket_at': null,
  'last_business_name': null,
  'business_names': <String>[],
};

Map<String, Object?> person(
  int id,
  String name,
  String address,
  Map<String, Object?> t,
) => {
  'id': id,
  'full_name': name,
  'address': address,
  'phone_number': null,
  'created_at': '2026-10-01T00:00:00Z',
  'ticket_totals': t,
};

// The owner of business 12 ("Synthetic Vendor"): 2 tickets, ₱500 unpaid and
// no warnings, so the card shows "2 tickets" and "₱500.00 unpaid" only.
final owner = person(
  40,
  'Synthetic Vendor',
  'Synthetic Street, Marikina',
  totals(offenses: 2, unpaid: 500),
);

// Juan was ticketed at this business; Pedro only somewhere else.
final juan = person(
  1,
  'Juan Dela Cruz',
  '1 Shoe Ave',
  totals(offenses: 1, warnings: 1),
);
final pedro = person(3, 'Pedro Reyes', '3 Shoe Ave', totals(offenses: 1));

// A second business (13) and its owner, to check that a late reply for
// business 12 never lands on business 13.
const otherBusiness = VendorSummary(
  id: 13,
  username: null,
  type: BusinessType.public,
  businessAccountNumber: 'TEST-13',
  stallNumber: 'B-3',
  tradeName: 'Other Market Goods',
  lastName: 'Owner',
  firstName: 'Other',
  middleName: null,
  address: 'Other Street, Marikina',
  marketSectionId: 1,
  marketSectionName: 'Section A',
);
final otherOwner = person(
  41,
  'Other Owner',
  'Other Street, Marikina',
  totals(),
);

Response<Object?> noContent(RequestOptions options) =>
    Response<Object?>(requestOptions: options, statusCode: 204);

DioException offline(RequestOptions options) => DioException(
  requestOptions: options,
  type: DioExceptionType.connectionError,
);

Finder inReview(Finder finder) =>
    find.descendant(of: find.byType(PersonIdentityReview), matching: finder);

Finder inSheet(Finder finder) =>
    find.descendant(of: find.byType(FindPersonSheet), matching: finder);

Future<void> showReview(
  WidgetTester tester,
  InspectionBloc bloc,
  ValueChanged<PersonCandidate?> onChanged, {
  VendorSummary? business = vendor,
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(390, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    BlocProvider.value(
      value: bloc,
      child: MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: SingleChildScrollView(
              child: PersonIdentityReview(
                vendor: business,
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  if (settle) await flush(tester);
}

// Types into the find sheet and waits out the typing pause.
Future<void> typeName(WidgetTester tester, String text) async {
  await tester.enterText(inSheet(find.byType(TextField)), text);
  await tester.pump(AppTheme.inspectionSearchDelay);
  await flush(tester);
}

// Opens the find sheet from the entry page, searches and taps [name].
Future<void> chooseViolator(
  WidgetTester tester, {
  required String button,
  required String typed,
  required String name,
}) async {
  await tester.ensureVisible(inReview(find.text(button)));
  await tester.tap(inReview(find.text(button)));
  await flush(tester);
  await typeName(tester, typed);
  await tester.tap(inSheet(find.text(name)));
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

  group('owner card', () {
    testWidgets('A: a found owner shows short tags; one tap selects the owner, '
        'then only Change and History remain', (tester) async {
      final requests = <RequestOptions>[];
      final bloc = await tester.runAsync(
        () => listBloc((options) async {
          requests.add(options);
          switch (options.path) {
            case '/vendor/12/owner-person':
              return reply(options, owner);
            case '/persons/40/tickets':
              return reply(options, {'items': [], 'has_more': false});
            default:
              throw StateError('Unexpected request: ${options.path}');
          }
        }),
      );
      final reports = <PersonCandidate?>[];
      await showReview(tester, bloc!, reports.add);

      expect(requests.map((r) => '${r.method} ${r.path}'), [
        'GET /vendor/12/owner-person',
      ]);
      expect(find.text('Violator'), findsOneWidget);
      expect(find.text('Synthetic Vendor'), findsOneWidget);
      expect(find.text('Owner'), findsOneWidget);
      expect(find.text('2 tickets'), findsOneWidget);
      expect(find.text('₱500.00 unpaid'), findsOneWidget);
      expect(find.text('0 warnings'), findsNothing);
      expect(find.text('Helper'), findsOneWidget);
      for (final removed in [
        'People at this business',
        'Registered owner of this business.',
        'Add helper or another person',
        'Paper violator name',
        'Check possible matches',
        'Find owner',
      ]) {
        expect(find.text(removed), findsNothing, reason: removed);
      }

      await tester.tap(find.text('Synthetic Vendor'));
      await tester.pump();
      expect(reports.map((p) => p?.id), [40]);
      expect(reports.single!.fullName, 'Synthetic Vendor');
      // The chosen card is read as selected, not as a disabled button.
      final semantics = tester.ensureSemantics();
      expect(
        tester.getSemantics(
          find.descendant(
            of: find.byType(PersonResultCard),
            matching: find.byType(MergeSemantics),
          ),
        ),
        isSemantics(isSelected: true, isButton: false, hasEnabledState: false),
      );
      semantics.dispose();
      expect(find.text('Change'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Helper'), findsNothing);
      expect(find.textContaining('Confirmed person:'), findsNothing);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // History opens the person's citation history.
      await tester.tap(find.text('History'));
      await flush(tester);
      expect(find.byType(PersonHistorySheet), findsOneWidget);
      expect(requests.last.path, '/persons/40/tickets');
      await tester.tap(find.text('Close').last);
      await flush(tester);

      // Change un-chooses; the owner card can be chosen again without
      // asking the server again.
      await tester.tap(find.text('Change'));
      await tester.pump();
      expect(reports.map((p) => p?.id), [40, null]);
      expect(find.text('Helper'), findsOneWidget);
      await tester.tap(find.text('Synthetic Vendor'));
      await tester.pump();
      expect(reports.map((p) => p?.id), [40, null, 40]);
      expect(
        requests.where((r) => r.path == '/vendor/12/owner-person'),
        hasLength(1),
      );
    });

    testWidgets('B: owner not found: "Add owner as person" sends one POST, '
        'shows it is busy, and selects the returned person', (tester) async {
      final requests = <RequestOptions>[];
      final saving = Completer<void>();
      final bloc = await tester.runAsync(
        () => listBloc((options) async {
          requests.add(options);
          if (options.path != '/vendor/12/owner-person') {
            throw StateError('Unexpected request: ${options.path}');
          }
          if (options.method == 'GET') return noContent(options);
          await saving.future;
          return reply(options, owner);
        }),
      );
      final reports = <PersonCandidate?>[];
      await showReview(tester, bloc!, reports.add);

      // The name comes from the business record; nothing to type.
      expect(find.text('Synthetic Vendor'), findsOneWidget);
      expect(find.text('Add owner as person'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      Finder addButton() => find.byWidgetPredicate(
        (w) => w is AppPrimaryButton && w.label == 'Add owner as person',
      );
      await tester.tap(find.text('Add owner as person'));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
      // Busy: the button is locked and shows it is working.
      expect(tester.widget<AppPrimaryButton>(addButton()).isLoading, isTrue);
      final busyButton = tester.widget<ElevatedButton>(
        find.descendant(of: addButton(), matching: find.byType(ElevatedButton)),
      );
      expect(busyButton.onPressed, isNull);
      // A double tap while busy sends nothing more.
      await tester.tap(find.text('Add owner as person'), warnIfMissed: false);
      await tester.pump();
      expect(requests.where((r) => r.method == 'POST'), hasLength(1));

      saving.complete();
      await flush(tester);
      final posts = requests.where((r) => r.method == 'POST').toList();
      expect(posts, hasLength(1));
      expect(posts.single.path, '/vendor/12/owner-person');
      expect(posts.single.data, isNull);
      expect(reports.map((p) => p?.id), [40]);
      expect(find.text('Change'), findsOneWidget);
      expect(find.text('Add owner as person'), findsNothing);
    });

    testWidgets('B: a failed add shows the reason and can be tried again', (
      tester,
    ) async {
      var posts = 0;
      final bloc = await tester.runAsync(
        () => listBloc((options) async {
          if (options.method == 'GET') return noContent(options);
          if (++posts == 1) throw offline(options);
          return reply(options, owner);
        }),
      );
      final reports = <PersonCandidate?>[];
      await showReview(tester, bloc!, reports.add);
      await tester.tap(find.text('Add owner as person'));
      await flush(tester);
      expect(
        find.text('No internet connection. Please try again.'),
        findsOneWidget,
      );
      expect(reports, isEmpty);
      await tester.tap(find.text('Add owner as person'));
      await flush(tester);
      expect(posts, 2);
      expect(reports.map((p) => p?.id), [40]);
    });

    testWidgets('F: loading, then an error with Retry that loads the owner', (
      tester,
    ) async {
      var calls = 0;
      final first = Completer<void>();
      final bloc = await tester.runAsync(
        () => listBloc((options) async {
          if (++calls == 1) {
            await first.future;
            throw offline(options);
          }
          return reply(options, owner);
        }),
      );
      await showReview(tester, bloc!, (_) {}, settle: false);
      await tester.pump();
      expect(find.text('Loading owner…'), findsOneWidget);
      expect(find.text('Helper'), findsOneWidget);

      first.complete();
      await flush(tester);
      expect(find.text('Loading owner…'), findsNothing);
      expect(
        find.text('No internet connection. Please try again.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Retry'));
      await flush(tester);
      expect(calls, 2);
      expect(find.text('Synthetic Vendor'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('F: the server message is shown when there is one', (
      tester,
    ) async {
      final bloc = await tester.runAsync(
        () => listBloc(
          (options) async => throw DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response<Object?>(
              requestOptions: options,
              statusCode: 404,
              data: {'message': 'Business not found.'},
            ),
          ),
        ),
      );
      await showReview(tester, bloc!, (_) {});
      expect(find.text('Business not found.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('1a: a slow owner add finishing after someone else was '
        'chosen keeps that person chosen', (tester) async {
      final saving = Completer<void>();
      final bloc = await tester.runAsync(
        () => listBloc((options) async {
          switch ('${options.method} ${options.path}') {
            case 'GET /vendor/12/owner-person':
              return noContent(options);
            case 'POST /vendor/12/owner-person':
              await saving.future;
              return reply(options, owner);
            case 'GET /vendor/12/people':
              return reply(options, []);
            case 'POST /persons/matches':
              return reply(options, {
                'items': [pedro],
                'has_more': false,
              });
            default:
              throw StateError('Unexpected request: ${options.path}');
          }
        }),
      );
      final reports = <PersonCandidate?>[];
      await showReview(tester, bloc!, reports.add);
      await tester.tap(find.text('Add owner as person'));
      await tester.pump();
      await chooseViolator(
        tester,
        button: 'Helper',
        typed: 'pedro',
        name: 'Pedro Reyes',
      );
      expect(reports.map((p) => p?.id), [3]);

      saving.complete();
      await flush(tester);
      expect(reports.map((p) => p?.id), [3]);
      expect(inReview(find.text('Pedro Reyes')), findsOneWidget);
      // The owner card now shows the added owner, ready to be chosen.
      await tester.tap(find.text('Change'));
      await tester.pump();
      expect(find.text('Synthetic Vendor'), findsOneWidget);
      expect(find.text('Add owner as person'), findsNothing);
    });

    testWidgets('1b: a late owner reply for another business is ignored', (
      tester,
    ) async {
      final slowFirst = Completer<void>();
      final bloc = await tester.runAsync(
        () => listBloc((options) async {
          switch (options.path) {
            case '/vendor/12/owner-person':
              await slowFirst.future;
              return reply(options, owner);
            case '/vendor/13/owner-person':
              return reply(options, otherOwner);
            default:
              throw StateError('Unexpected request: ${options.path}');
          }
        }),
      );
      // Business 12 is shown and its owner is still loading when the
      // enforcer switches to business 13.
      await showReview(tester, bloc!, (_) {}, settle: false);
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      await showReview(tester, bloc, (_) {}, business: otherBusiness);
      expect(find.text('Other Owner'), findsOneWidget);

      slowFirst.complete();
      await flush(tester);
      expect(find.text('Other Owner'), findsOneWidget);
      expect(find.text('Synthetic Vendor'), findsNothing);
    });

    test('1c: two adds for one business send one POST; a pending add does '
        'not block another business', () async {
      final posts = <String>[];
      final slowFirst = Completer<void>();
      final bloc = await listBloc((options) async {
        posts.add(options.path);
        if (options.path == '/vendor/12/owner-person') {
          await slowFirst.future;
          return reply(options, owner);
        }
        return reply(options, otherOwner);
      });
      final addedOther = bloc.stream.firstWhere(
        (state) => state is OwnerPersonAdded && state.businessId == 13,
      );
      bloc.add(OwnerPersonAddRequested(12));
      bloc.add(OwnerPersonAddRequested(12));
      bloc.add(OwnerPersonAddRequested(13));
      await addedOther.timeout(const Duration(seconds: 5));

      final addedFirst = bloc.stream.firstWhere(
        (state) => state is OwnerPersonAdded && state.businessId == 12,
      );
      slowFirst.complete();
      await addedFirst.timeout(const Duration(seconds: 5));
      expect(posts.where((path) => path == '/vendor/12/owner-person'), [
        '/vendor/12/owner-person',
      ]);
      expect(posts.where((path) => path == '/vendor/13/owner-person'), [
        '/vendor/13/owner-person',
      ]);
    });

    test('2: a name search reports its results with no separate loading '
        'state', () async {
      final bloc = await listBloc(
        (options) async => reply(options, {
          'items': [pedro],
          'has_more': false,
        }),
      );
      final states = <String>[];
      final listening = bloc.stream.listen(
        (state) => states.add(state.runtimeType.toString()),
      );
      final loaded = bloc.stream.firstWhere(
        (state) => state is PersonMatchesLoaded,
      );
      bloc.add(PersonMatchesRequested('pe'));
      await loaded;
      await listening.cancel();
      expect(states, ['PersonMatchesLoaded']);
    });

    testWidgets('E: an unregistered vendor has no owner card, only '
        '"Find violator"', (tester) async {
      final paths = <String>[];
      final bloc = await tester.runAsync(
        () => listBloc((options) async {
          paths.add(options.path);
          return reply(options, []);
        }),
      );
      await showReview(tester, bloc!, (_) {}, business: null);
      expect(paths, isEmpty);
      expect(find.text('Violator'), findsOneWidget);
      expect(find.text('Find violator'), findsOneWidget);
      expect(find.text('Helper'), findsNothing);
      expect(find.text('Owner'), findsNothing);
      expect(find.text('Add owner as person'), findsNothing);
    });
  });

  group('find person sheet', () {
    testWidgets('C: people ticketed here come first and tagged; under 2 '
        'letters nothing is searched; 2+ searches by name only; a tap '
        'returns the person', (tester) async {
      final requests = <RequestOptions>[];
      final bloc = await tester.runAsync(
        () => listBloc((options) async {
          requests.add(options);
          switch (options.path) {
            case '/vendor/12/owner-person':
              return noContent(options);
            case '/vendor/12/people':
              return reply(options, [juan]);
            case '/persons/matches':
              // The server lists Pedro first; Juan was ticketed here.
              return reply(options, {
                'items': [pedro, juan],
                'has_more': false,
              });
            default:
              throw StateError('Unexpected request: ${options.path}');
          }
        }),
      );
      final reports = <PersonCandidate?>[];
      await showReview(tester, bloc!, reports.add);
      await tester.tap(find.text('Helper'));
      await flush(tester);

      // Before typing: the people already ticketed at this business.
      expect(find.byType(FindPersonSheet), findsOneWidget);
      expect(requests.last.path, '/vendor/12/people');
      expect(inSheet(find.text('Juan Dela Cruz')), findsOneWidget);
      expect(inSheet(find.text('Ticketed here')), findsOneWidget);
      expect(
        tester
            .widget<TextField>(inSheet(find.byType(TextField)))
            .decoration
            ?.hintText,
        'Type the name',
      );

      // One letter: no search.
      await typeName(tester, 'r');
      expect(requests.where((r) => r.path == '/persons/matches'), isEmpty);

      // Two letters: a name-only search.
      await typeName(tester, 're');
      final searches = requests
          .where((r) => r.path == '/persons/matches')
          .toList();
      expect(searches, hasLength(1));
      expect(searches.single.data, {'name': 're', 'offset': 0});
      final juanTop = tester.getTopLeft(inSheet(find.text('Juan Dela Cruz')));
      final pedroTop = tester.getTopLeft(inSheet(find.text('Pedro Reyes')));
      expect(juanTop.dy, lessThan(pedroTop.dy));
      expect(inSheet(find.text('Ticketed here')), findsOneWidget);
      expect(
        tester.getTopLeft(inSheet(find.text('Ticketed here'))).dy,
        lessThan(pedroTop.dy),
      );
      expect(inSheet(find.text('3 Shoe Ave')), findsOneWidget);
      expect(inSheet(find.text('1 ticket')), findsNWidgets(2));
      expect(inSheet(find.text('1 warning')), findsOneWidget);

      await tester.tap(inSheet(find.text('Pedro Reyes')));
      await flush(tester);
      expect(find.byType(FindPersonSheet), findsNothing);
      expect(reports.map((p) => p?.id), [3]);
      expect(inReview(find.text('Pedro Reyes')), findsOneWidget);
    });

    testWidgets('C: an unregistered vendor searches with nothing listed '
        'first; no match says so briefly; More results asks for the next '
        'page', (tester) async {
      final requests = <RequestOptions>[];
      final bloc = await tester.runAsync(
        () => listBloc((options) async {
          requests.add(options);
          final data = options.data as Map;
          if (data['name'] == 'zz') {
            return reply(options, {'items': [], 'has_more': false});
          }
          return reply(options, {
            'items': data['offset'] == 0 ? [pedro] : [juan],
            'has_more': data['offset'] == 0,
          });
        }),
      );
      final reports = <PersonCandidate?>[];
      await showReview(tester, bloc!, reports.add, business: null);
      await tester.tap(find.text('Find violator'));
      await flush(tester);
      expect(requests, isEmpty);
      expect(inSheet(find.text('Ticketed here')), findsNothing);

      await typeName(tester, 'zz');
      expect(
        find.text('No match. Check the spelling or add a new person.'),
        findsOneWidget,
      );

      await typeName(tester, 'pe');
      expect(inSheet(find.text('Pedro Reyes')), findsOneWidget);
      await tester.tap(find.text('More results'));
      await flush(tester);
      expect((requests.last.data as Map)['offset'], 1);
      expect(inSheet(find.text('Pedro Reyes')), findsOneWidget);
      expect(inSheet(find.text('Juan Dela Cruz')), findsOneWidget);
      expect(find.text('More results'), findsNothing);
    });

    testWidgets('D: "Add new person" opens a short create sheet with the '
        'typed name; the created person is selected', (tester) async {
      final requests = <RequestOptions>[];
      final bloc = await tester.runAsync(
        () => listBloc((options) async {
          requests.add(options);
          switch (options.path) {
            case '/persons/matches':
              return reply(options, {'items': [], 'has_more': false});
            case '/persons':
              return reply(options, {
                'id': 50,
                'full_name': 'Maria Santos',
                'address': '5 Shoe Ave',
              });
            default:
              throw StateError('Unexpected request: ${options.path}');
          }
        }),
      );
      final reports = <PersonCandidate?>[];
      await showReview(tester, bloc!, reports.add, business: null);
      await tester.tap(find.text('Find violator'));
      await flush(tester);
      await typeName(tester, 'Maria Santos');
      await tester.tap(find.text('Not listed? Add new person'));
      await flush(tester);

      expect(find.byType(CreatePersonSheet), findsOneWidget);
      expect(find.text('New person'), findsOneWidget);
      expect(
        find.text(
          'Create only after reviewing possible matches. Existing registry details can be changed by an admin.',
        ),
        findsNothing,
      );
      String field(String label) => tester
          .widget<TextField>(
            find.descendant(
              of: find.widgetWithText(TextFormField, label),
              matching: find.byType(TextField),
            ),
          )
          .controller!
          .text;
      expect(field('Full name'), 'Maria Santos');
      expect(field('Address'), '');

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Address'),
        '5 Shoe Ave',
      );
      await tester.tap(find.text('Create person'));
      await flush(tester);
      final created = requests.singleWhere((r) => r.path == '/persons');
      expect(created.data, {
        'full_name': 'Maria Santos',
        'address': '5 Shoe Ave',
        'phone_number': null,
      });
      expect(find.byType(CreatePersonSheet), findsNothing);
      expect(find.byType(FindPersonSheet), findsNothing);
      expect(reports.map((p) => p?.id), [50]);
    });

    testWidgets('D: an unconfirmed create keeps Create locked with a short '
        'message', (tester) async {
      final bloc = await tester.runAsync(
        () => listBloc((options) async {
          if (options.path == '/persons') throw offline(options);
          return reply(options, {'items': [], 'has_more': false});
        }),
      );
      await showReview(tester, bloc!, (_) {}, business: null);
      await tester.tap(find.text('Find violator'));
      await flush(tester);
      await typeName(tester, 'Maria Santos');
      await tester.tap(find.text('Not listed? Add new person'));
      await flush(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Address'),
        '5 Shoe Ave',
      );
      await tester.tap(find.text('Create person'));
      await flush(tester);
      expect(
        find.text(
          'Could not confirm it was saved. Close and search again before '
          'retrying.',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Create person'),
            )
            .onPressed,
        isNull,
      );
    });

    testWidgets('4: a create the server refused shows its message and the '
        'way forward; Create stays locked', (tester) async {
      final bloc = await tester.runAsync(
        () => listBloc((options) async {
          if (options.path == '/persons') {
            throw DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              response: Response<Object?>(
                requestOptions: options,
                statusCode: 400,
                data: {'message': 'Address is too long.'},
              ),
            );
          }
          return reply(options, {'items': [], 'has_more': false});
        }),
      );
      await showReview(tester, bloc!, (_) {}, business: null);
      await tester.tap(find.text('Find violator'));
      await flush(tester);
      await typeName(tester, 'Maria Santos');
      await tester.tap(find.text('Not listed? Add new person'));
      await flush(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Address'),
        '5 Shoe Ave',
      );
      await tester.tap(find.text('Create person'));
      await flush(tester);
      expect(
        find.text(
          'Address is too long. Close and search again before retrying.',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Create person'),
            )
            .onPressed,
        isNull,
      );
    });

    testWidgets('A: a fresh search that fails clears the old results; Try '
        'again searches from the first page', (tester) async {
      final offsets = <Object?>[];
      var calls = 0;
      final bloc = await tester.runAsync(
        () => listBloc((options) async {
          offsets.add((options.data as Map)['offset']);
          if (++calls == 2) throw offline(options);
          return reply(options, {
            'items': [pedro],
            'has_more': false,
          });
        }),
      );
      await showReview(tester, bloc!, (_) {}, business: null);
      await tester.tap(find.text('Find violator'));
      await flush(tester);
      await typeName(tester, 'pe');
      expect(inSheet(find.text('Pedro Reyes')), findsOneWidget);

      // The keyboard Search key starts a fresh search, which fails.
      await tester.showKeyboard(inSheet(find.byType(TextField)));
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await flush(tester);
      const failed =
          'Request could not be confirmed. Check records before trying again.';
      expect(inSheet(find.text(failed)), findsOneWidget);
      expect(inSheet(find.text('Pedro Reyes')), findsNothing);

      await tester.tap(inSheet(find.text('Try again')));
      await flush(tester);
      expect(offsets, [0, 0, 0]);
      expect(inSheet(find.text('Pedro Reyes')), findsOneWidget);
    });

    testWidgets('6: a failed "More results" keeps the people shown and '
        'offers Try again below them', (tester) async {
      final offsets = <Object?>[];
      var failedOnce = false;
      final bloc = await tester.runAsync(
        () => listBloc((options) async {
          final offset = (options.data as Map)['offset'];
          offsets.add(offset);
          if (offset == 0) {
            return reply(options, {
              'items': [pedro],
              'has_more': true,
            });
          }
          if (!failedOnce) {
            failedOnce = true;
            throw offline(options);
          }
          return reply(options, {
            'items': [juan],
            'has_more': false,
          });
        }),
      );
      await showReview(tester, bloc!, (_) {}, business: null);
      await tester.tap(find.text('Find violator'));
      await flush(tester);
      await typeName(tester, 'pe');
      await tester.tap(find.text('More results'));
      await flush(tester);

      const failed =
          'Request could not be confirmed. Check records before trying again.';
      expect(inSheet(find.text('Pedro Reyes')), findsOneWidget);
      expect(inSheet(find.text(failed)), findsOneWidget);
      expect(
        tester.getTopLeft(inSheet(find.text(failed))).dy,
        greaterThan(tester.getTopLeft(inSheet(find.text('Pedro Reyes'))).dy),
      );

      await tester.tap(inSheet(find.text('Try again')));
      await flush(tester);
      expect(offsets, [0, 1, 1]);
      expect(inSheet(find.text(failed)), findsNothing);
      expect(inSheet(find.text('Pedro Reyes')), findsOneWidget);
      expect(inSheet(find.text('Juan Dela Cruz')), findsOneWidget);
    });

    group('7: the "Ticketed here" list before typing', () {
      Future<InspectionBloc> sheetBloc(
        WidgetTester tester,
        Future<Response<Object?>> Function(RequestOptions) people,
      ) async => (await tester.runAsync(
        () => listBloc((options) async {
          switch (options.path) {
            case '/vendor/12/owner-person':
              return noContent(options);
            case '/vendor/12/people':
              return people(options);
            default:
              throw StateError('Unexpected request: ${options.path}');
          }
        }),
      ))!;

      testWidgets('shows that it is loading, then the people', (tester) async {
        final loading = Completer<void>();
        final bloc = await sheetBloc(tester, (options) async {
          await loading.future;
          return reply(options, [juan]);
        });
        await showReview(tester, bloc, (_) {});
        await tester.tap(find.text('Helper'));
        await tester.pump();
        await tester.pump();
        expect(inSheet(find.text('Loading people…')), findsOneWidget);
        loading.complete();
        await flush(tester);
        expect(inSheet(find.text('Loading people…')), findsNothing);
        expect(inSheet(find.text('Juan Dela Cruz')), findsOneWidget);
        expect(inSheet(find.text('Ticketed here')), findsOneWidget);
      });

      testWidgets('shows the error with Try again, which loads the list', (
        tester,
      ) async {
        var calls = 0;
        final bloc = await sheetBloc(tester, (options) async {
          if (++calls == 1) throw offline(options);
          return reply(options, [juan]);
        });
        await showReview(tester, bloc, (_) {});
        await tester.tap(find.text('Helper'));
        await flush(tester);
        expect(
          inSheet(find.text('No internet connection. Please try again.')),
          findsOneWidget,
        );
        await tester.tap(inSheet(find.text('Try again')));
        await flush(tester);
        expect(calls, 2);
        expect(inSheet(find.text('Juan Dela Cruz')), findsOneWidget);
      });

      testWidgets('with nobody ticketed here, asks for the name', (
        tester,
      ) async {
        final bloc = await sheetBloc(
          tester,
          (options) async => reply(options, []),
        );
        await showReview(tester, bloc, (_) {});
        await tester.tap(find.text('Helper'));
        await flush(tester);
        expect(inSheet(find.text('Type the name to search.')), findsOneWidget);
        expect(inSheet(find.text('Ticketed here')), findsNothing);
      });
    });
  });
}
