import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
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
import 'package:marikina_market_mobile/features/tickets/domain/entities/person_candidate.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_state.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/pages/add_new_inspection_page.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/pages/new_inspection_preview_page.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/add_photo_evidence_btn.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/bottom_sheets/select_ordinance_bottom_sheet.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/inspection_type_toggle.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/scan_paper_btn.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/ticket_violation_card.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/violator_info_card.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/ticket_paper_field.dart';

import 'features/auth/data/login_mobile_contract_test.dart'
    show profileResponse, reply;
import 'features/auth/login_mobile_flow_test.dart' show loginBloc;
import 'features/auth/login_test_network_info.dart';
import 'features/tickets/data/models/ordinance_model_test.dart'
    show ordinanceResponse;
import 'features/tickets/presentation/person_verification_flow_test.dart'
    show BoundaryImageCompressor;
import 'inspection_list_ui_test.dart' show listBloc;
import 'inspection_preview_navigation_test.dart' show flush, formAction, vendor;
import 'review_verify_test.dart' show calculation, verifiedAnswer;
import 'violator_picker_test.dart'
    show chooseViolator, inReview, juan, noContent, pedro, showReview;

// Criterion 7, user decision 2026-11-10: the violator's name always comes from
// the chosen person's record. There is no name box: choosing a person shows
// the record name; Change un-chooses the person (and clears the ordinances,
// which depend on the person); choosing again gives the record name back. So
// a ticket can only go ahead with the record name. Synthetic people; expected
// values are worked out by hand.

String paperField(WidgetTester tester, String label) => tester
    .widget<TicketPaperField>(
      find.byWidgetPredicate((w) => w is TicketPaperField && w.label == label),
    )
    .value;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    final adapter = OrdinanceHiveModelAdapter();
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
  });

  testWidgets('Change un-chooses the person; choosing again gives the record '
      'name back', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    final bloc = await tester.runAsync(
      () => listBloc((options) async {
        switch (options.path) {
          case '/vendor/12/owner-person':
            return noContent(options);
          case '/vendor/12/people':
            return reply(options, [juan]);
          case '/persons/matches':
            return reply(options, {
              'items': [pedro],
              'has_more': false,
            });
          default:
            throw StateError('Unexpected request: ${options.path}');
        }
      }),
    );
    final reports = <(int?, String?)>[];
    await showReview(
      tester,
      bloc!,
      (PersonCandidate? p) => reports.add((p?.id, p?.fullName)),
    );

    // Search with a short spelling and choose Pedro Reyes (person 3).
    await chooseViolator(
      tester,
      button: 'Someone else',
      typed: 'pedro',
      name: 'Pedro Reyes',
    );
    expect(reports.last, (3, 'Pedro Reyes'));
    expect(inReview(find.text('Pedro Reyes')), findsOneWidget);

    // Change: he is no longer chosen.
    await tester.tap(find.text('Change'));
    await tester.pump();
    expect(reports.last, (null, null));
    expect(inReview(find.text('Pedro Reyes')), findsNothing);
    expect(find.text('Change'), findsNothing);

    // Search again with another spelling and choose him: the record name is
    // back.
    await chooseViolator(
      tester,
      button: 'Someone else',
      typed: 'P. Reyes',
      name: 'Pedro Reyes',
    );
    expect(reports.last, (3, 'Pedro Reyes'));
    expect(inReview(find.text('Pedro Reyes')), findsOneWidget);
  });

  group('on the entry page', () {
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

    testWidgets('Change clears the person and ordinances; after choosing '
        'again, Review and Verify carry the record name', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final compressor = FlutterImageCompressPlatform.instance;
      FlutterImageCompressPlatform.instance = BoundaryImageCompressor();
      addTearDown(() => FlutterImageCompressPlatform.instance = compressor);
      final verifyBodies = <Map<String, Object?>>[];
      final template = await tester.runAsync(
        () => listBloc((options) async {
          switch (options.path) {
            case '/persons/matches':
              return reply(options, {
                'items': [
                  {
                    'id': 31,
                    'full_name': 'Juan Dela Cruz',
                    'address': '31 Synthetic Market Lane',
                    'phone_number': null,
                    'matched_fields': ['name'],
                  },
                ],
                'has_more': false,
              });
            case '/vendor/12/owner-person':
              return noContent(options);
            case '/vendor/12/people':
              return reply(options, []);
            case '/persons/31/tickets':
              return reply(options, {'items': [], 'has_more': false});
            case '/ordinance':
              return reply(options, [ordinanceResponse]);
            case '/enforcer/tickets/fine-summary':
              return reply(options, calculation);
            case '/enforcer/tickets/verify':
              verifyBodies.add(Map<String, Object?>.from(options.data as Map));
              return reply(options, verifiedAnswer());
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
          verifyInspectionUseCase: templateBloc.verifyInspectionUseCase,
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
      tester
          .widget<InspectionTypeToggle>(find.byType(InspectionTypeToggle))
          .onChange(ViolationType.ticket);
      await tester.pump();

      Future<void> choosePerson(String typed) => chooseViolator(
        tester,
        button: 'Someone else',
        typed: typed,
        name: 'Juan Dela Cruz',
      );

      Future<void> tapSelectOrdinance() async {
        await tester.ensureVisible(find.text('Select ordinance'));
        await tester.tap(find.text('Select ordinance'));
        await tester.pump();
      }

      Future<void> chooseOrdinance() async {
        await tapSelectOrdinance();
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

      // Choose Juan Dela Cruz (person 31) after typing a shorter spelling,
      // then pick Section 69 "Proper Waste Disposal".
      await choosePerson('Juan Cruz');
      expect(inReview(find.text('Juan Dela Cruz')), findsOneWidget);
      List<int> chosenOrdinances() => tester
          .widget<TicketViolationCard>(find.byType(TicketViolationCard))
          .ordinances
          .map((item) => item.id)
          .toList();
      await chooseOrdinance();
      expect(chosenOrdinances(), [1]);
      expect(find.textContaining('Proper Waste Disposal'), findsWidgets);

      // Change: the person and the ordinance are both gone, and the
      // ordinance list refuses to open until a person is chosen again.
      await tester.ensureVisible(inReview(find.text('Change')));
      await tester.tap(inReview(find.text('Change')));
      await tester.pump();
      expect(inReview(find.text('Juan Dela Cruz')), findsNothing);
      expect(chosenOrdinances(), isEmpty);
      expect(find.textContaining('Proper Waste Disposal'), findsNothing);
      await tapSelectOrdinance();
      expect(find.text('Choose the violator first.'), findsOneWidget);
      expect(find.byType(SelectOrdinanceBottomSheet), findsNothing);

      // Choose him again: the record name is back; pick the ordinance again.
      await choosePerson('J. Cruz');
      expect(inReview(find.text('Juan Dela Cruz')), findsOneWidget);
      await chooseOrdinance();

      // Fill in the rest so the Review page opens.
      await tester.ensureVisible(find.byKey(const ValueKey('paper-reference')));
      await tester.enterText(
        find.byKey(const ValueKey('paper-reference')),
        '000100',
      );
      await tester.ensureVisible(find.byKey(const ValueKey('issue-place')));
      await tester.enterText(
        find.byKey(const ValueKey('issue-place')),
        'Fish aisle near F-014',
      );
      final folder = await tester.runAsync(
        () => Directory.systemTemp.createTemp('record-name-'),
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
        await tester.runAsync(() => folder!.delete(recursive: true));
      });
      final file = File('${folder!.path}/evidence.png');
      await tester.runAsync(
        () => File('assets/logo/org_logo.png').copy(file.path),
      );
      final paper = XFile(
        (await tester.runAsync(
          () => file.copy('${folder.path}/paper.png'),
        ))!.path,
      );
      await tester.runAsync(() async {
        final context = tester.element(find.byType(AddNewInspectionPage));
        await precacheImage(FileImage(file), context);
        await precacheImage(FileImage(File(paper.path)), context);
      });
      tester
          .widget<ScanPaperBtn>(find.byType(ScanPaperBtn))
          .onPhotoAdded(paper);
      for (final control in tester.widgetList<AddPhotoEvidenceBtn>(
        find.byType(AddPhotoEvidenceBtn),
      )) {
        control.onPhotoAdded(XFile(file.path));
      }
      await flush(tester);
      await tester.enterText(
        find.byKey(const ValueKey('inspection-description')),
        'Market identification card not displayed',
      );

      // Review shows the same name on both lines.
      await tester.ensureVisible(formAction());
      tester.widget<AppPrimaryButton>(formAction()).onPressed!();
      await flush(tester);
      expect(find.byType(NewInspectionPreviewPage), findsOneWidget);
      expect(paperField(tester, 'RECORDED VIOLATOR:'), 'Juan Dela Cruz');
      expect(paperField(tester, 'CONFIRMED PERSON:'), 'Juan Dela Cruz');

      // Verify sends the record name with the chosen person.
      await tester.ensureVisible(find.text('Verify ticket'));
      await tester.tap(find.text('Verify ticket'));
      await flush(tester);
      expect(verifyBodies, hasLength(1));
      expect(verifyBodies.single['paper_violator_name'], 'Juan Dela Cruz');
      expect(verifyBodies.single['person_id'], 31);
      expect(tester.takeException(), isNull);
    });
  });
}
