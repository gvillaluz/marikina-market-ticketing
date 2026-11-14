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
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_state.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/pages/add_new_inspection_page.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/pages/new_inspection_preview_page.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/bottom_sheets/select_ordinance_bottom_sheet.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/copy_to_paper_card.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/ticket_violation_card.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/violator_info_card.dart';

import 'features/auth/data/login_mobile_contract_test.dart'
    show profileResponse, reply;
import 'features/auth/login_mobile_flow_test.dart' show loginBloc;
import 'features/auth/login_test_network_info.dart';
import 'features/tickets/data/models/ordinance_model_test.dart'
    show ordinanceResponse;
import 'inspection_list_ui_test.dart' show listBloc;
import 'inspection_preview_navigation_test.dart' show flush, formAction, vendor;
import 'unregistered_entry_test.dart' show sectionList;
import 'violator_picker_test.dart'
    show chooseViolator, inReview, noContent, otherBusiness, owner, pedro;

// Changing the business or the market section clears the chosen violator and
// what depends on them (the ordinances), so the page can never send someone
// chosen for another business. The network is fake; expected values are
// worked out by hand.

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

  Future<List<String>> openEntryPage(WidgetTester tester) async {
    // Wide screen: the test font is wider than the real one, which would
    // make the one-line "missing ordinance" message overflow at phone width.
    tester.view.physicalSize = const Size(800, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final paths = <String>[];
    final template = await tester.runAsync(
      () => listBloc((options) async {
        paths.add('${options.method} ${options.path}');
        switch (options.path) {
          case '/vendor/12/owner-person':
            return reply(options, owner);
          case '/vendor/13/owner-person':
            return noContent(options);
          case '/vendor/12/people' || '/vendor/13/people':
            return reply(options, []);
          case '/marketsection':
            return reply(options, sectionList);
          case '/persons/matches':
            return reply(options, {
              'items': [pedro],
              'has_more': false,
            });
          case '/ordinance':
            return reply(options, [ordinanceResponse]);
          case '/ordinance/shortcuts':
            return reply(options, const {
              'person_ordinance_ids': <int>[],
              'my_recent_ordinance_ids': <int>[],
              'most_violated_ordinance_ids': <int>[],
            });
          case '/enforcer/tickets/warning-check':
            return reply(options, []);
          default:
            throw DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
            );
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
        getOrdinanceShortcutsUseCase: templateBloc.getOrdinanceShortcutsUseCase,
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
          (route) => route is GoRoute && route.name == Routes.newInspectionName,
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
    return paths;
  }

  Future<void> tapSelectOrdinance(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Select ordinance'));
    await tester.tap(find.text('Select ordinance'));
    await tester.pump();
  }

  Future<void> chooseOrdinance(WidgetTester tester) async {
    await tapSelectOrdinance(tester);
    final selectionBloc = tester
        .element(find.byType(SelectOrdinanceBottomSheet))
        .read<InspectionBloc>();
    for (
      var attempt = 0;
      attempt < 100 &&
          selectionBloc.state is! OrdinanceSelectionLoaded &&
          selectionBloc.state is! OrdinanceSelectionError;
      attempt++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(selectionBloc.state, isA<OrdinanceSelectionLoaded>());
    await flush(tester);
    await tester.tap(
      find.text(
        'Ord No. ${ordinanceResponse['ordinance_no']}, Series of ${ordinanceResponse['series']}',
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Confirm selection'));
    await flush(tester);
  }

  // The violator name the page gives the copy-to-paper card.
  String copyName(WidgetTester tester) =>
      tester.widget<CopyToPaperCard>(find.byType(CopyToPaperCard)).name;

  List<int> chosenOrdinances(WidgetTester tester) => tester
      .widget<TicketViolationCard>(find.byType(TicketViolationCard))
      .ordinances
      .map((item) => item.id)
      .toList();

  // After the change nobody is chosen: the copy card has no name, the
  // ordinances are gone, the ordinance list waits for a person, and Next
  // does not open Review.
  Future<void> expectNobodyChosen(WidgetTester tester) async {
    expect(inReview(find.text('Change')), findsNothing);
    expect(copyName(tester), '');
    expect(chosenOrdinances(tester), isEmpty);
    await tapSelectOrdinance(tester);
    expect(find.text('Choose the violator first.'), findsOneWidget);
    expect(find.byType(SelectOrdinanceBottomSheet), findsNothing);
    await tester.ensureVisible(formAction());
    tester.widget<AppPrimaryButton>(formAction()).onPressed!();
    await flush(tester);
    expect(find.byType(NewInspectionPreviewPage), findsNothing);
  }

  testWidgets('8a: Change Vendor clears the owner chosen for business 12; '
      'business 13 starts with nobody chosen', (tester) async {
    final paths = await openEntryPage(tester);
    tester
        .widget<ViolatorInfoCard>(find.byType(ViolatorInfoCard))
        .onVendorSelected(vendor);
    await flush(tester);
    await tester.ensureVisible(inReview(find.text('Synthetic Vendor')));
    await tester.tap(inReview(find.text('Synthetic Vendor')));
    await tester.pump();
    await chooseOrdinance(tester);
    expect(copyName(tester), 'Synthetic Vendor');
    expect(chosenOrdinances(tester), [1]);

    await tester.ensureVisible(find.text('Change Vendor'));
    await tester.tap(find.text('Change Vendor'));
    await flush(tester);
    tester
        .widget<ViolatorInfoCard>(find.byType(ViolatorInfoCard))
        .onVendorSelected(otherBusiness);
    await flush(tester);
    expect(paths, contains('GET /vendor/13/owner-person'));
    expect(inReview(find.text('Add owner as person')), findsOneWidget);
    await expectNobodyChosen(tester);
  });

  testWidgets('8b: Change section clears the violator chosen for an '
      'unregistered vendor', (tester) async {
    await openEntryPage(tester);
    await tester.tap(find.text('Unregistered'));
    await flush(tester);
    await tester.tap(find.text('Meat Section'));
    await flush(tester);
    await chooseViolator(
      tester,
      button: 'Find violator',
      typed: 'pedro',
      name: 'Pedro Reyes',
    );
    await chooseOrdinance(tester);
    expect(copyName(tester), 'Pedro Reyes');
    expect(chosenOrdinances(tester), [1]);

    await tester.ensureVisible(find.byTooltip('Change section'));
    await tester.tap(find.byTooltip('Change section'));
    await flush(tester);
    await tester.tap(find.text('Vegetable Section'));
    await flush(tester);
    await expectNobodyChosen(tester);
  });
}
