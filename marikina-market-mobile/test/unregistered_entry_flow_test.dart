import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
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
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_state.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/pages/add_new_inspection_page.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/pages/new_inspection_preview_page.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/add_photo_evidence_btn.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/bottom_sheets/select_ordinance_bottom_sheet.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/inspection_type_toggle.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/scan_paper_btn.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/unregistered_section_banner.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/violator_info_card.dart';

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
import 'unregistered_entry_test.dart' show sectionList;
import 'violator_picker_test.dart' show chooseViolator, inReview, noContent;

// Faster entry B2, the whole entry page for an unregistered vendor: choose
// Unregistered, pick the market section, type the place, then Next, Verify
// and (for tickets) a section change that forces Verify again, and finally
// Submit. The network is fake and refuses the save, so nothing is uploaded;
// the test reads what the page tried to send.

const calculation = {
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
      'is_duplicate': false,
    },
  ],
};

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

  for (final type in ViolationType.values) {
    testWidgets('${type.value}: unregistered vendor from section to review page', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final compressor = FlutterImageCompressPlatform.instance;
      FlutterImageCompressPlatform.instance = BoundaryImageCompressor();
      addTearDown(() => FlutterImageCompressPlatform.instance = compressor);
      final paths = <String>[];
      final verifyBodies = <Map<String, Object?>>[];
      Map<String, Object?>? warningCheckBody;
      Map<String, String>? savedFields;
      final template = await tester.runAsync(
        () => listBloc((options) async {
          paths.add(options.path);
          switch (options.path) {
            case '/marketsection':
              return reply(options, sectionList);
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
            case '/persons/31/tickets':
              return reply(options, {'items': [], 'has_more': false});
            case '/ordinance':
              return reply(options, [ordinanceResponse]);
            case '/enforcer/tickets/warning-check':
              warningCheckBody = Map<String, Object?>.from(options.data as Map);
              return reply(options, []);
            case '/enforcer/tickets/fine-summary':
              return reply(options, calculation);
            case '/enforcer/tickets/verify':
              verifyBodies.add(Map<String, Object?>.from(options.data as Map));
              return reply(options, {
                'reviewed_calculation': 'reviewed-calculation',
                'reviewed_business_snapshot': null,
                'business_snapshot': null,
                'calculation': calculation,
              });
            case '/enforcer/tickets/new-inspection':
              savedFields = Map.fromEntries((options.data as FormData).fields);
              throw DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
              );
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

      // A business picked first and then changed: its place must not carry over.
      expect(find.text('Scan QR Code'), findsNothing);
      tester
          .widget<ViolatorInfoCard>(find.byType(ViolatorInfoCard))
          .onVendorSelected(vendor);
      await flush(tester);
      await tester.tap(find.text('Change Vendor'));
      await flush(tester);
      final ownerRequests = paths
          .where((path) => path.startsWith('/vendor'))
          .length;
      expect(ownerRequests, 1);

      // Choose Unregistered, then the market section from the office list.
      await tester.tap(find.text('Unregistered'));
      await flush(tester);
      expect(find.text('Closed Section'), findsNothing);
      await tester.tap(find.text('Meat Section'));
      await flush(tester);
      expect(find.byType(UnregisteredSectionBanner), findsOneWidget);
      expect(find.text('Unregistered vendor'), findsOneWidget);
      expect(find.text('Meat Section'), findsOneWidget);
      expect(find.text('Change Vendor'), findsNothing);
      expect(inReview(find.text('Owner')), findsNothing);
      expect(
        paths.where((path) => path.startsWith('/vendor')).length,
        ownerRequests,
        reason: 'No business, so no owner is requested.',
      );

      tester
          .widget<InspectionTypeToggle>(find.byType(InspectionTypeToggle))
          .onChange(type);
      await tester.pump();
      final isTicket = type == ViolationType.ticket;
      final placeKey = ValueKey(
        isTicket ? 'issue-place' : 'warning-issue-place',
      );
      // The place starts empty: the enforcer types where it happened.
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(placeKey),
                matching: find.byType(TextField),
              ),
            )
            .controller!
            .text,
        '',
      );
      await tester.ensureVisible(find.byKey(placeKey));
      await tester.enterText(find.byKey(placeKey), 'Near gate 2');
      if (isTicket) {
        await tester.ensureVisible(
          find.byKey(const ValueKey('paper-reference')),
        );
        await tester.enterText(
          find.byKey(const ValueKey('paper-reference')),
          '000456',
        );
      }
      // No business, so no owner card: "Find violator" is the only way.
      expect(inReview(find.text('Someone else')), findsNothing);
      Future<void> chooseJuan() => chooseViolator(
        tester,
        button: 'Find violator',
        typed: 'Juan Cruz',
        name: 'Juan Dela Cruz',
      );
      await chooseJuan();

      Future<void> chooseOrdinance() async {
        await tester.ensureVisible(find.text('Select ordinance'));
        await tester.tap(find.text('Select ordinance'));
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
        // Confirm selection must work with no business: it is the section
        // and the person that matter.
        await tester.tap(find.text('Confirm selection'));
        await flush(tester);
      }

      await chooseOrdinance();
      if (!isTicket) {
        expect(warningCheckBody!['vendor_id'], isNull);
        expect(warningCheckBody!['person_id'], 31);
      }

      final folder = await tester.runAsync(
        () => Directory.systemTemp.createTemp('b2-flow-photo-'),
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
        'Keep the aisle clear.',
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

      final submit = find.byWidgetPredicate(
        (widget) =>
            widget is AppPrimaryButton &&
            widget.label == 'Submit ${type.value}',
      );
      final review = await openReview();
      expect(review.formData.vendorSummary, isNull);
      expect(review.formData.unregisteredSection?.id, 5);
      expect(review.formData.issuePlace, 'Near gate 2');
      expect(find.text('Unregistered vendor'), findsWidgets);
      expect(find.text('Meat Section'), findsWidgets);
      expect(find.text('TRADE NAME:'), findsNothing);

      if (isTicket) {
        expect(tester.widget<AppPrimaryButton>(submit).onPressed, isNull);
        await tester.ensureVisible(find.text('Verify ticket'));
        await tester.tap(find.text('Verify ticket'));
        await flush(tester);
        expect(verifyBodies.single['vendor_id'], isNull);
        expect(verifyBodies.single['market_section_id'], 5);
        expect(tester.widget<AppPrimaryButton>(submit).onPressed, isNotNull);

        // A different section is a change: Verify is needed again.
        router.pop();
        await flush(tester);
        expect(
          find.text('Information changed. Verify again before submitting.'),
          findsNothing,
        );
        await tester.ensureVisible(find.byTooltip('Change section'));
        await tester.tap(find.byTooltip('Change section'));
        await flush(tester);
        await tester.tap(find.text('Vegetable Section'));
        await flush(tester);
        // A new section starts with nobody chosen: choose the violator and
        // the ordinance again.
        expect(inReview(find.text('Change')), findsNothing);
        await chooseJuan();
        await chooseOrdinance();
        expect(
          find.text('Information changed. Verify again before submitting.'),
          findsOneWidget,
        );
        final changed = await openReview();
        expect(changed.formData.unregisteredSection?.id, 7);
        expect(tester.widget<AppPrimaryButton>(submit).onPressed, isNull);
        await tester.ensureVisible(find.text('Verify ticket'));
        await tester.tap(find.text('Verify ticket'));
        await flush(tester);
        expect(verifyBodies.last['market_section_id'], 7);
        expect(tester.widget<AppPrimaryButton>(submit).onPressed, isNotNull);
      }

      // Submit: what the page sends has the section and no business.
      expect(savedFields, isNull);
      await tester.ensureVisible(find.text('Submit ${type.value}'));
      await tester.tap(find.text('Submit ${type.value}'));
      await flush(tester);
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is AppPrimaryButton &&
              RegExp(r'^(Issue ticket|Confirm warning)').hasMatch(widget.label),
        ),
      );
      for (var attempt = 0; attempt < 100 && savedFields == null; attempt++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(savedFields, isNotNull);
      expect(savedFields!['market_section_id'], isTicket ? '7' : '5');
      expect(savedFields!.containsKey('vendor_id'), isFalse);
      expect(savedFields!['issue_place'], 'Near gate 2');
      expect(
        paths.where((path) => path == '/enforcer/tickets/new-inspection'),
        hasLength(1),
      );
      await flush(tester);
      expect(tester.takeException(), isNull);
    });
  }
}
