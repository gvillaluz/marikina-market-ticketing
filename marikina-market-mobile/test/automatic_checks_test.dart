import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:marikina_market_mobile/core/connectivity/cubit/connectivity_cubit.dart';
import 'package:marikina_market_mobile/core/di/dependency_injection.dart';
import 'package:marikina_market_mobile/core/router/app_routes.dart';
import 'package:marikina_market_mobile/core/router/mobile_route_access.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/app_primary_btn.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/auth/data/models/user_model.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_hive_model.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_event.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_state.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/pages/add_new_inspection_page.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/pages/new_inspection_preview_page.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/bottom_sheets/select_ordinance_bottom_sheet.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/inspection_type_toggle.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/violator_info_card.dart';

import 'features/auth/data/login_mobile_contract_test.dart'
    show profileResponse, reply;
import 'features/auth/login_mobile_flow_test.dart' show loginBloc;
import 'features/auth/login_test_network_info.dart';
import 'features/tickets/data/models/ordinance_model_test.dart'
    show ordinanceResponse;
import 'inspection_list_ui_test.dart' show listBloc;
import 'inspection_preview_navigation_test.dart' show flush, formAction, vendor;
import 'ordinance_shortcuts_test.dart' show withNoShortcuts;
import 'violator_picker_test.dart'
    show chooseViolator, inReview, inSheet, noContent, typeName;

// Automatic checks (criterion 3): the entry page names what is missing, the
// duplicate and control-number checks are shown to the enforcer, and a person
// is never picked or created for the enforcer. The network is fake; nothing
// is saved.

const personMatch = {
  'id': 31,
  'full_name': 'Juan Dela Cruz',
  'address': '31 Synthetic Market Lane',
  'phone_number': null,
  'matched_fields': ['name'],
};

Map<String, Object?> calculation({required bool duplicate}) => {
  'total_payment_amount': 100,
  'highest_severity': 'Minor',
  'breakdown': [
    {
      'ordinance_id': 1,
      'ordinance_no': '123',
      'section': '53',
      'payment_amount': 100,
      'fine_kind': 'Fixed',
      'severity': 'Minor',
      'offense_number': 1,
      'is_duplicate': duplicate,
    },
  ],
};

DioException conflict(RequestOptions options, String message) => DioException(
  requestOptions: options,
  type: DioExceptionType.badResponse,
  response: Response<Object?>(
    requestOptions: options,
    statusCode: 409,
    data: {'message': message},
  ),
);

String ordinanceTile() =>
    'Ord No. ${ordinanceResponse['ordinance_no']}, Series of ${ordinanceResponse['series']}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    final adapter = OrdinanceHiveModelAdapter();
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
  });
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await sl.reset();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
          'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
          (_) async => const StandardMessageCodec().encodeMessage([null]),
        );
  });
  tearDown(() async {
    await sl.reset();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
          'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
          null,
        );
  });

  group('the ordinance list refuses a repeat', () {
    Future<List<Object?>> openSheet(
      WidgetTester tester, {
      required bool warning,
      required Future<Response<Object?>> Function(RequestOptions) respond,
    }) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final bloc = await tester.runAsync(
        () => listBloc(withNoShortcuts(respond)),
      );
      await tester.runAsync(() async {
        final loaded = bloc!.stream.firstWhere(
          (state) => state is OrdinanceSelectionLoaded,
        );
        bloc.add(LoadOrdinanceSelection());
        await loaded;
      });
      final committed = <Object?>[];
      await tester.pumpWidget(
        BlocProvider<InspectionBloc>.value(
          value: bloc!,
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: SelectOrdinanceBottomSheet(
                isWarningTicket: warning,
                ordinances: const [],
                onChanged: committed.add,
                vendorId: 12,
                personId: 31,
              ),
            ),
          ),
        ),
      );
      await flush(tester);
      await tester.tap(find.text(ordinanceTile()));
      await tester.pump();
      await tester.tap(find.text('Confirm selection'));
      await flush(tester);
      return committed;
    }

    testWidgets('a citation already active today for this person', (
      tester,
    ) async {
      final committed = await openSheet(
        tester,
        warning: false,
        respond: (options) async => options.path == '/ordinance'
            ? reply(options, [ordinanceResponse])
            : reply(options, calculation(duplicate: true)),
      );
      expect(
        find.text(
          'This person already has an active citation for a selected ordinance today. Change the selection.',
        ),
        findsOneWidget,
      );
      expect(find.byType(SelectOrdinanceBottomSheet), findsOneWidget);
      expect(committed, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('a warning this person already received', (tester) async {
      final committed = await openSheet(
        tester,
        warning: true,
        respond: (options) async => options.path == '/ordinance'
            ? reply(options, [ordinanceResponse])
            : reply(options, [
                {
                  'ordinance_id': 1,
                  'ordinance_no': '123',
                  'section': '53',
                  'specific_category': null,
                },
              ]),
      );
      expect(
        find.text(
          'This person has already received a lifetime warning for this ordinance. Change the selection.',
        ),
        findsOneWidget,
      );
      expect(committed, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('a clean ordinance is accepted', (tester) async {
      final committed = await openSheet(
        tester,
        warning: false,
        respond: (options) async => options.path == '/ordinance'
            ? reply(options, [ordinanceResponse])
            : reply(options, calculation(duplicate: false)),
      );
      expect(committed, hasLength(1));
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('the entry page', () {
    final requests = <RequestOptions>[];

    Future<void> openEntryPage(
      WidgetTester tester, {
      List<Object?> matches = const [],
      double width = 390,
    }) async {
      requests.clear();
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final template = await tester.runAsync(
        () => listBloc((options) async {
          requests.add(options);
          switch (options.path) {
            case '/persons/matches':
              return reply(options, {'items': matches, 'has_more': false});
            case '/vendor/12/owner-person':
              return noContent(options);
            case '/vendor/12/people':
              return reply(options, []);
            case '/persons/31/tickets':
              return reply(options, {'items': [], 'has_more': false});
            case '/ordinance':
              return reply(options, [ordinanceResponse]);
            case '/ordinance/shortcuts':
              return reply(options, const {
                'person_ordinance_ids': <int>[],
                'my_recent_ordinance_ids': <int>[],
                'most_violated_ordinance_ids': <int>[],
              });
            default:
              throw StateError('Unexpected request: ${options.path}');
          }
        }),
      );
      // Close the catalog cache outside the fake clock, also when the test
      // fails half way; otherwise the shared teardown waits for 10 minutes.
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        var cacheClosed = false;
        final closingCache = Hive.box<OrdinanceHiveModel>(
          'ordinances',
        ).close().then((_) => cacheClosed = true);
        for (var attempt = 0; attempt < 100 && !cacheClosed; attempt++) {
          await tester.pump();
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
        }
        await closingCache;
      });
      final connectivity = ConnectivityCubit(LoginTestNetworkInfo());
      await tester.runAsync(() => template!.loadOrdinancesUseCase());
      late AuthBloc auth;
      await tester.runAsync(() async {
        auth = loginBloc(
          connectivity,
          (options) async => throw StateError('No auth HTTP expected.'),
        );
        await auth.stream.firstWhere((state) => state is Unauthenticated);
        final authenticated = auth.stream.firstWhere(
          (state) => state is Authenticated,
        );
        auth.add(UserUpdated(UserModel.fromJson(profileResponse).toEntity()));
        await authenticated;
      });
      sl.registerSingleton<AuthBloc>(auth);
      final templateBloc = template!;
      sl.registerFactory<InspectionBloc>(
        () => InspectionBloc(
          matchPeopleUseCase: templateBloc.matchPeopleUseCase,
          createPersonUseCase: templateBloc.createPersonUseCase,
          getPersonHistoryUseCase: templateBloc.getPersonHistoryUseCase,
          loadInspectionListUseCase: templateBloc.loadInspectionListUseCase,
          loadOrdinancesUseCase: templateBloc.loadOrdinancesUseCase,
          getMarketSectionsUseCase: templateBloc.getMarketSectionsUseCase,
          searchBusinessesUseCase: templateBloc.searchBusinessesUseCase,
          getOrdinanceShortcutsUseCase:
              templateBloc.getOrdinanceShortcutsUseCase,
          getBusinessPeopleUseCase: templateBloc.getBusinessPeopleUseCase,
          getOwnerPersonUseCase: templateBloc.getOwnerPersonUseCase,
          addOwnerPersonUseCase: templateBloc.addOwnerPersonUseCase,
          getFineSummaryUseCase: templateBloc.getFineSummaryUseCase,
          checkWarningOrdinancesUseCase:
              templateBloc.checkWarningOrdinancesUseCase,
          saveInspectionTicketUseCase: templateBloc.saveInspectionTicketUseCase,
        ),
      );
      final router = GoRouter(
        initialLocation: Routes.newInspection,
        routes: [
          ...buildAppRoutes().where(
            (route) =>
                route is GoRoute && route.name == Routes.newInspectionName,
          ),
          GoRoute(
            path: Routes.dashboard,
            builder: (_, _) => const Scaffold(body: Text('Fallback dashboard')),
          ),
        ],
        redirect: (_, state) =>
            MobileRouteAccess.redirect(auth.state, state.uri.path),
      );
      addTearDown(() async {
        router.dispose();
        await auth.close();
        await connectivity.close();
      });
      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      );
      await flush(tester);
      final formBloc = tester
          .element(find.byType(AddNewInspectionPage))
          .read<InspectionBloc>();
      for (
        var attempt = 0;
        attempt < 100 && formBloc.ordinances.isEmpty;
        attempt++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(formBloc.ordinances, isNotEmpty);
      tester
          .widget<ViolatorInfoCard>(find.byType(ViolatorInfoCard))
          .onVendorSelected(vendor);
      await flush(tester);
    }

    // Searches in the find sheet, then closes it without choosing anyone.
    Future<void> searchThenClose(WidgetTester tester, String name) async {
      await tester.ensureVisible(inReview(find.text('Helper')));
      await tester.tap(inReview(find.text('Helper')));
      await flush(tester);
      await typeName(tester, name);
    }

    Future<void> closeSheet(WidgetTester tester) async {
      await tester.tap(inSheet(find.byTooltip('Close')));
      await flush(tester);
    }

    Future<void> tapSelectOrdinance(WidgetTester tester) async {
      await tester.ensureVisible(find.text('Select ordinance'));
      await tester.tap(find.text('Select ordinance'));
      await flush(tester);
    }

    for (final type in ViolationType.values) {
      testWidgets('${type.value}: Next names every missing item', (
        tester,
      ) async {
        // Wide screen: the test font is wider than the real one, which would
        // make the one-line messages overflow at phone width.
        await openEntryPage(tester, width: 800);
        tester
            .widget<InspectionTypeToggle>(find.byType(InspectionTypeToggle))
            .onChange(type);
        await tester.pump();
        await tester.ensureVisible(formAction());
        tester.widget<AppPrimaryButton>(formAction()).onPressed!();
        await flush(tester);

        expect(find.text('Please select at least one ordinance.'), findsOne);
        expect(find.text('Description is required.'), findsWidgets);
        if (type == ViolationType.ticket) {
          expect(
            find.text(
              'One paper ticket photo and at least one supporting photo are required for tickets.',
            ),
            findsOneWidget,
          );
          expect(find.text('Control number is required.'), findsOneWidget);
        } else {
          expect(
            find.text('One paper warning photo is required.'),
            findsOneWidget,
          );
        }
        expect(find.byType(NewInspectionPreviewPage), findsNothing);
        expect(
          requests.where((r) => r.path == '/enforcer/tickets/new-inspection'),
          isEmpty,
        );
      });
    }

    testWidgets(
      'an ordinance cannot be picked before the person is confirmed',
      (tester) async {
        await openEntryPage(tester);
        await tapSelectOrdinance(tester);
        expect(find.text('Choose the violator first.'), findsOneWidget);
        expect(find.byType(SelectOrdinanceBottomSheet), findsNothing);
      },
    );

    testWidgets('a suggested person must be tapped before ordinances open', (
      tester,
    ) async {
      await openEntryPage(tester, matches: [personMatch]);
      await searchThenClose(tester, 'Juan');
      expect(inSheet(find.text('Juan Dela Cruz')), findsOneWidget);
      await closeSheet(tester);
      await tapSelectOrdinance(tester);
      expect(find.text('Choose the violator first.'), findsOneWidget);
      expect(find.byType(SelectOrdinanceBottomSheet), findsNothing);

      await chooseViolator(
        tester,
        button: 'Helper',
        typed: 'Juan',
        name: 'Juan Dela Cruz',
      );
      await tapSelectOrdinance(tester);
      expect(find.byType(SelectOrdinanceBottomSheet), findsOneWidget);
    });

    testWidgets('no match: nobody is created and ordinances stay closed', (
      tester,
    ) async {
      await openEntryPage(tester);
      await searchThenClose(tester, 'A Name Nobody Has Registered');
      expect(
        find.text('No match. Check the spelling or add a new person.'),
        findsOneWidget,
      );
      expect(find.text('Not listed? Add new person'), findsOneWidget);
      await closeSheet(tester);
      // The owner has no person record yet; it is not added without a tap.
      expect(inReview(find.text('Add owner as person')), findsOneWidget);
      await tapSelectOrdinance(tester);
      expect(find.byType(SelectOrdinanceBottomSheet), findsNothing);
      expect(
        requests.where((r) => r.method == 'POST' && r.path == '/persons'),
        isEmpty,
      );
      expect(
        requests.where(
          (r) => r.method == 'POST' && r.path == '/vendor/12/owner-person',
        ),
        isEmpty,
      );
    });
  });
}
