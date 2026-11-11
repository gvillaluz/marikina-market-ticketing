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
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/app_primary_btn.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/auth/data/models/user_model.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_hive_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_model.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/inspection_form_data.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_state.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/pages/add_new_inspection_page.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/pages/new_inspection_preview_page.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/add_photo_evidence_btn.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/bottom_sheets/select_ordinance_bottom_sheet.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/inspection_type_toggle.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/scan_paper_btn.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/violator_info_card.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/preview/photo_evidence_preview_section.dart';

import 'features/auth/data/login_mobile_contract_test.dart'
    show profileResponse, reply;
import 'features/auth/login_mobile_flow_test.dart' show loginBloc;
import 'features/auth/login_test_network_info.dart';
import 'features/tickets/data/models/ordinance_model_test.dart'
    show ordinanceResponse;
import 'features/tickets/presentation/business_snapshot_test.dart'
    show snapshot;
import 'features/tickets/presentation/person_verification_flow_test.dart'
    show BoundaryImageCompressor;
import 'fine_summary_display_test.dart' show line, summaryOf;
import 'inspection_list_ui_test.dart' show listBloc;
import 'inspection_preview_navigation_test.dart' show flush, formAction, vendor;
import 'violator_picker_test.dart' show inReview;

// Criterion 5, Review and Verify. The Review page shows the paper ticket photo
// next to the details; Verify only asks the server to check, it never saves;
// a mistake is fixed by going Back to the entry page, which keeps what was
// typed, and the fixed detail is what the next Verify checks. The network is
// fake; the tests read which requests the phone made and what they carried.

const calculation = {
  'total_payment_amount': 500,
  'highest_severity': 'Minor',
  'breakdown': [
    {
      'ordinance_id': 1,
      'ordinance_no': '123',
      'section': '53',
      'payment_amount': 500,
      'fine_kind': 'Fixed',
      'severity': 'Minor',
      'offense_number': 1,
      'is_duplicate': false,
    },
  ],
};

Map<String, Object?> verifiedAnswer() => {
  'reviewed_calculation': 'reviewed-calculation',
  'reviewed_business_snapshot': 'reviewed-business',
  'business_snapshot': snapshot,
  'calculation': calculation,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    final adapter = OrdinanceHiveModelAdapter();
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
  });

  group('the Review page', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    Future<(InspectionBloc, InspectionFormData, List<String>)> openReview(
      WidgetTester tester,
    ) async {
      final folder = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('review-verify-'),
      ))!;
      // Windows keeps an open image file locked: let go of the page and the
      // image cache before the photos are deleted.
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
        await tester.runAsync(() => folder.delete(recursive: true));
      });
      Future<XFile> photo(String name) async => XFile(
        (await tester.runAsync(
          () => File('assets/logo/org_logo.png').copy('${folder.path}/$name'),
        ))!.path,
      );
      final paper = await photo('paper.png');
      final stall = await photo('stall.png');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() async {
        final context = tester.element(find.byType(SizedBox));
        await precacheImage(FileImage(File(paper.path)), context);
        await precacheImage(FileImage(File(stall.path)), context);
      });
      final paths = <String>[];
      final bloc = (await tester.runAsync(
        () => listBloc((options) async {
          paths.add(options.path);
          if (options.path == '/enforcer/tickets/verify') {
            return reply(options, verifiedAnswer());
          }
          throw StateError('Unexpected request: ${options.path}');
        }),
      ))!;
      addTearDown(bloc.close);
      final draft = InspectionFormData(
        vendorSummary: vendor,
        enforcerId: 7,
        personId: 31,
        personFullName: 'Juan Dela Cruz',
        paperViolatorName: 'Juan Cruz',
        paperReference: '000456',
        issuePlace: 'Fish aisle near F-014',
        description: 'Market identification card not displayed',
        ticketType: ViolationType.ticket,
        penaltyType: PenaltyType.cashFine,
        communityServiceHrs: null,
        fineSummary: summaryOf([line(1, '53', 1, amount: 500)], total: 500),
        ordinances: [OrdinanceModel.fromJson(ordinanceResponse).toEntity()],
        paperTicketPhoto: paper,
        evidences: [stall],
      );
      tester.view.physicalSize = const Size(400, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: BlocProvider<InspectionBloc>.value(
            value: bloc,
            child: NewInspectionPreviewPage(formData: draft),
          ),
        ),
      );
      await flush(tester);
      return (bloc, draft, paths);
    }

    testWidgets(
      'shows the paper ticket photo apart from the supporting photo',
      (tester) async {
        final (_, draft, _) = await openReview(tester);

        expect(find.text('Paper ticket photo'), findsOneWidget);
        final sections = tester
            .widgetList<PhotoEvidencePreviewSection>(
              find.byType(PhotoEvidencePreviewSection),
            )
            .map((section) => section.evidences.map((p) => p.path).toList())
            .toList();
        expect(sections, [
          [draft.paperTicketPhoto!.path],
          [draft.evidences!.single.path],
        ]);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    testWidgets('Verify only asks the server to check, even when pressed '
        'twice', (tester) async {
      final (bloc, _, paths) = await openReview(tester);
      final verify = find.byWidgetPredicate(
        (w) => w is AppPrimaryButton && w.label == 'Verify ticket',
      );
      for (var press = 0; press < 2; press++) {
        await tester.ensureVisible(verify);
        final checked = bloc.stream.firstWhere(
          (state) => state is InspectionVerified,
        );
        await tester.tap(verify);
        await tester.runAsync(
          () => checked.timeout(const Duration(seconds: 5)),
        );
        await flush(tester);
      }

      expect(paths, ['/enforcer/tickets/verify', '/enforcer/tickets/verify']);
      expect(find.byType(NewInspectionPreviewPage), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('fixing a mistake', () {
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

    testWidgets('Back keeps what was typed, and Verify checks the fixed '
        'control number', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final compressor = FlutterImageCompressPlatform.instance;
      FlutterImageCompressPlatform.instance = BoundaryImageCompressor();
      addTearDown(() => FlutterImageCompressPlatform.instance = compressor);
      final paths = <String>[];
      final verifyBodies = <Map<String, Object?>>[];
      final template = await tester.runAsync(
        () => listBloc((options) async {
          paths.add(options.path);
          switch (options.path) {
            case '/vendor/12/owner-person':
              // The business owner already has person record 31.
              return reply(options, {
                'id': 31,
                'full_name': 'Synthetic Vendor',
                'address': 'Synthetic Street, Marikina',
                'phone_number': null,
              });
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

      // Fill in a ticket for a registered business.
      tester
          .widget<ViolatorInfoCard>(find.byType(ViolatorInfoCard))
          .onVendorSelected(vendor);
      await flush(tester);
      tester
          .widget<InspectionTypeToggle>(find.byType(InspectionTypeToggle))
          .onChange(ViolationType.ticket);
      await tester.pump();
      const reference = ValueKey('paper-reference');
      const place = ValueKey('issue-place');
      const description = ValueKey('inspection-description');
      String typed(Finder field) => tester
          .widget<TextField>(
            find
                .descendant(
                  of: field,
                  matching: find.byType(TextField),
                  matchRoot: true,
                )
                .first,
          )
          .controller!
          .text;
      await tester.ensureVisible(find.byKey(reference));
      await tester.enterText(find.byKey(reference), '000100');
      await tester.ensureVisible(find.byKey(place));
      await tester.enterText(find.byKey(place), 'Fish aisle near F-014');
      // One tap on the owner card chooses the owner as the violator.
      final owner = inReview(find.text('Synthetic Vendor'));
      await tester.ensureVisible(owner);
      await tester.tap(owner);
      await tester.pump();

      await tester.ensureVisible(find.text('Select Ordinance'));
      await tester.tap(find.text('Select Ordinance'));
      await tester.pump();
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

      final folder = await tester.runAsync(
        () => Directory.systemTemp.createTemp('review-verify-flow-'),
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
        find.byKey(description),
        'Market identification card not displayed',
      );

      Future<NewInspectionPreviewPage> openReview() async {
        await tester.ensureVisible(formAction());
        tester.widget<AppPrimaryButton>(formAction()).onPressed!();
        await flush(tester);
        expect(find.byType(NewInspectionPreviewPage), findsOneWidget);
        return tester.widget<NewInspectionPreviewPage>(
          find.byType(NewInspectionPreviewPage),
        );
      }

      Future<void> verify() async {
        await tester.ensureVisible(find.text('Verify ticket'));
        await tester.tap(find.text('Verify ticket'));
        await flush(tester);
      }

      // What the entry page holds before Review. (The violator's name is
      // the chosen person's record name.)
      final before = [
        typed(find.byKey(reference)),
        typed(find.byKey(place)),
        typed(find.byKey(description)),
      ];
      expect(before, [
        '000100',
        'Fish aisle near F-014',
        'Market identification card not displayed',
      ]);
      expect(inReview(find.text('Synthetic Vendor')), findsOneWidget);
      expect(inReview(find.text('Change')), findsOneWidget);

      // Review, with a wrong control number typed by mistake.
      final review = await openReview();
      expect(review.formData.paperReference, '000100');
      expect(review.formData.paperTicketPhoto?.path, paper.path);
      await verify();
      expect(verifyBodies.single['paper_reference'], '000100');

      // Back: the entry page still holds everything that was typed.
      router.pop();
      await flush(tester);
      expect(find.byType(NewInspectionPreviewPage), findsNothing);
      expect([
        typed(find.byKey(reference)),
        typed(find.byKey(place)),
        typed(find.byKey(description)),
      ], before);
      expect(inReview(find.text('Synthetic Vendor')), findsOneWidget);
      expect(inReview(find.text('Change')), findsOneWidget);

      // Fix the number; the next Verify checks the fixed one with the rest
      // unchanged.
      await tester.ensureVisible(find.byKey(reference));
      await tester.enterText(find.byKey(reference), '000457');
      await tester.pump();
      final fixed = await openReview();
      expect(fixed.formData.paperReference, '000457');
      await verify();
      expect(verifyBodies, hasLength(2));
      expect(verifyBodies.last['paper_reference'], '000457');
      expect(verifyBodies.last['issue_place'], 'Fish aisle near F-014');
      expect(verifyBodies.last['paper_violator_name'], 'Synthetic Vendor');
      expect(verifyBodies.last['person_id'], 31);
      expect(verifyBodies.last['vendor_id'], 12);
      expect(paths, isNot(contains('/enforcer/tickets/new-inspection')));
      await flush(tester);
      expect(tester.takeException(), isNull);
    });
  });
}
