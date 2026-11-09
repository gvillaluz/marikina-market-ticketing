import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
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
import 'package:marikina_market_mobile/features/tickets/domain/entities/vendor_summary.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/fine_summary.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/severity.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/fine_summary_section.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/business_type.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_state.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/bottom_sheets/select_ordinance_bottom_sheet.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/pages/add_new_inspection_page.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/pages/new_inspection_preview_page.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/add_photo_evidence_btn.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/copy_to_paper_card.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/scan_paper_btn.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/ticket_paper_field.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/inspection_type_toggle.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/violator_info_card.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/preview/submit_confirmation_bottom_sheet.dart';

import 'features/auth/data/login_mobile_contract_test.dart'
    show profileResponse, reply;
import 'features/auth/login_mobile_flow_test.dart' show loginBloc;
import 'features/auth/login_test_network_info.dart';
import 'features/tickets/data/models/ordinance_model_test.dart'
    show ordinanceResponse;
import 'inspection_list_ui_test.dart' show listBloc;

const vendor = VendorSummary(
  id: 12,
  username: 'synthetic-vendor',
  type: BusinessType.public,
  businessAccountNumber: 'TEST-12',
  stallNumber: 'A-12',
  tradeName: 'Synthetic Market Goods',
  lastName: 'Vendor',
  firstName: 'Synthetic',
  middleName: null,
  address: 'Synthetic Street, Marikina',
  marketSectionId: 1,
  marketSectionName: 'Section A',
);

Finder formAction() => find.byWidgetPredicate(
  (widget) =>
      widget is AppPrimaryButton &&
      RegExp(r'^(Next|Submit Ticket|Submit Warning)$').hasMatch(widget.label),
);

Future<void> flush(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 40)),
  );
  // Give real I/O a turn between fake-clock frames while loading animations
  // run. pumpAndSettle alone advances only fake time and can starve Hive/Dio.
  for (
    var attempt = 0;
    attempt < 100 && tester.binding.hasScheduledFrame;
    attempt++
  ) {
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
  }
  await tester.pumpAndSettle();
}

// Copy-to-paper card values by paper label, leaving out the date and time.
Map<String, String> copyCard(WidgetTester tester) => {
  for (final field in tester.widgetList<TicketPaperField>(
    find.descendant(
      of: find.byType(CopyToPaperCard),
      matching: find.byType(TicketPaperField),
    ),
  ))
    if (field.label != 'DATE / TIME:' && field.label != 'Petsa:')
      field.label: field.value,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final width in [280.0, 390.0, 800.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('fine total fits $width px at text scale $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                body: SingleChildScrollView(
                  padding: AppTheme.inspectionCardPadding,
                  child: FineSummarySection(
                    items: [],
                    fineSummary: FineSummary(
                      totalPaymentAmount: 12500.50,
                      severity: Severity.minor,
                      breakdownItems: [],
                    ),
                    isTicket: true,
                    onDelete: (_) => fail('Layout must not change selections.'),
                  ),
                ),
              ),
            ),
          ),
        );
        final label = find.text('Total Fine Amount: ');
        final amount = find.text('₱12,500.50');
        expect(label, findsOneWidget);
        expect(amount, findsOneWidget);
        final section = tester.getRect(find.byType(FineSummarySection));
        for (final finder in [label, amount]) {
          final rect = tester.getRect(finder);
          expect(rect.left, greaterThanOrEqualTo(section.left));
          expect(rect.right, lessThanOrEqualTo(section.right));
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
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

  test(
    'production preview route resolves to the canonical allowed location',
    () {
      final router = GoRouter(routes: buildAppRoutes());
      addTearDown(router.dispose);
      expect(
        router.namedLocation(Routes.newInspectionPreviewName),
        '/inspection/new/preview',
      );
      final enforcer = Authenticated(
        user: UserModel.fromJson(profileResponse).toEntity(),
      );
      expect(
        MobileRouteAccess.redirect(
          enforcer,
          router.namedLocation(Routes.newInspectionPreviewName),
        ),
        isNull,
      );
      final vendorAccount = Authenticated(
        user: UserModel.fromJson({
          ...profileResponse,
          'role': 'MarketVendor',
        }).toEntity(),
      );
      expect(
        MobileRouteAccess.redirect(vendorAccount, Routes.newInspectionPreview),
        Routes.mobileAccessUnavailable,
      );
    },
  );

  for (final width in [800.0, 390.0]) {
    for (final type in ViolationType.values) {
      testWidgets(
        '${type.value}: Next opens real preview at $width px without saving and Back retains the draft',
        (tester) async {
          tester.view.physicalSize = Size(width, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          var saveRequests = 0;
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
                case '/persons/31/tickets':
                  return reply(options, {'items': [], 'has_more': false});
                case '/vendor/12/people':
                  return reply(options, []);
                case '/enforcer/tickets/verify':
                  return reply(options, {
                    'reviewed_calculation': 'reviewed-calculation',
                    'reviewed_business_snapshot': 'reviewed-business',
                    'business_snapshot': {
                      'business_account_number': 'TEST-12',
                      'business_name': 'Synthetic Market Goods',
                      'registered_owner_name': 'Synthetic Vendor',
                      'business_type': 'Public',
                      'stall_number': 'A-12',
                      'market_section_name': 'Section A',
                      'business_address': 'Synthetic Street, Marikina',
                    },
                    'calculation': {
                      'total_payment_amount': 100,
                      'highest_severity': 'Minor',
                      'breakdown': [
                        {
                          'ordinance_id': 1,
                          'ordinance_no': ordinanceResponse['ordinance_no'],
                          'section': '53',
                          'payment_amount': 100,
                          'fine_kind': 'Fixed',
                          'severity': 'Minor',
                          'offense_number': 1,
                          'is_duplicate': false,
                        },
                      ],
                    },
                  });
                case '/ordinance':
                  return reply(options, [ordinanceResponse]);
                case '/enforcer/tickets/warning-check':
                  expect(options.data['person_id'], 31);
                  return reply(options, []);
                case '/enforcer/tickets/fine-summary':
                  return reply(options, {
                    'total_payment_amount': 100,
                    'highest_severity': 'Minor',
                    'breakdown': [
                      {
                        'ordinance_id': 1,
                        'ordinance_no': ordinanceResponse['ordinance_no'],
                        'section': '53',
                        'payment_amount': 100,
                        'fine_kind': 'Fixed',
                        'severity': 'Minor',
                        'offense_number': 1,
                        'is_duplicate': false,
                      },
                    ],
                  });
                case '/enforcer/tickets/new-inspection':
                  saveRequests++;
                  throw StateError('Preview must not save.');
                default:
                  throw StateError(
                    'Unexpected inspection request: ${options.path}',
                  );
              }
            }),
          );
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
            auth.add(
              UserUpdated(UserModel.fromJson(profileResponse).toEntity()),
            );
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
              searchVendorByCodeUseCase: templateBloc.searchVendorByCodeUseCase,
              searchBusinessesUseCase: templateBloc.searchBusinessesUseCase,
              getOrdinanceShortcutsUseCase:
                  templateBloc.getOrdinanceShortcutsUseCase,
              getBusinessPeopleUseCase: templateBloc.getBusinessPeopleUseCase,
              getFineSummaryUseCase: templateBloc.getFineSummaryUseCase,
              checkWarningOrdinancesUseCase:
                  templateBloc.checkWarningOrdinancesUseCase,
              saveInspectionTicketUseCase:
                  templateBloc.saveInspectionTicketUseCase,
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
                builder: (_, _) =>
                    const Scaffold(body: Text('Fallback dashboard')),
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
          await tester.pump();
          final name = find.byWidgetPredicate(
            (widget) =>
                widget is TextField &&
                widget.decoration?.labelText == 'Paper violator name',
          );
          Future<void> selectPerson() async {
            await tester.enterText(name, 'Juan Cruz');
            await tester.ensureVisible(find.text('Check possible matches'));
            await tester.tap(find.text('Check possible matches'));
            await flush(tester);
            await tester.ensureVisible(find.text('Same person – select'));
            await tester.tap(find.text('Same person – select'));
            await tester.pump();
          }

          // Switching Warning to Ticket keeps the person already chosen.
          if (type == ViolationType.ticket) await selectPerson();
          tester
              .widget<InspectionTypeToggle>(find.byType(InspectionTypeToggle))
              .onChange(type);
          await tester.pump();
          if (type == ViolationType.ticket) {
            expect(find.text('Selected'), findsOneWidget);
            expect(
              tester.widget<TextField>(name).controller!.text,
              'Juan Dela Cruz',
            );
          }
          // The issue place starts from the business record and stays editable.
          expect(
            tester
                .widget<TextField>(
                  find.descendant(
                    of: find.byKey(
                      ValueKey(
                        type == ViolationType.ticket
                            ? 'issue-place'
                            : 'warning-issue-place',
                      ),
                    ),
                    matching: find.byType(TextField),
                  ),
                )
                .controller!
                .text,
            'Section A, Stall A-12',
          );
          if (type == ViolationType.ticket) {
            expect(find.text('Control number'), findsOneWidget);
            expect(find.text('Issue place'), findsOneWidget);
            await tester.ensureVisible(
              find.byKey(const ValueKey('paper-reference')),
            );
            await tester.enterText(
              find.byKey(const ValueKey('paper-reference')),
              '000456',
            );
            await tester.ensureVisible(
              find.byKey(const ValueKey('issue-place')),
            );
            await tester.enterText(
              find.byKey(const ValueKey('issue-place')),
              'Fish aisle near F-014',
            );
          } else {
            await tester.ensureVisible(
              find.byKey(const ValueKey('warning-issue-place')),
            );
            await tester.enterText(
              find.byKey(const ValueKey('warning-issue-place')),
              'Fish aisle near F-014',
            );
          }
          if (type == ViolationType.warning) await selectPerson();
          await tester.ensureVisible(find.text('Select Ordinance'));
          await tester.tap(find.text('Select Ordinance'));
          await tester.pump();
          final selectionBloc = tester
              .element(find.byType(SelectOrdinanceBottomSheet))
              .read<InspectionBloc>();
          // Real Hive I/O and Dio's fake-clock scheduling both need progress.
          // Stop as soon as the actual sheet BLoC has finished loading.
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
          late XFile evidence;
          {
            final folder = await tester.runAsync(
              () => Directory.systemTemp.createTemp('preview-photo-'),
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
            evidence = XFile(file.path);
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
            final isTicket = type == ViolationType.ticket;
            final kind = isTicket ? 'ticket' : 'warning';
            // The paper photo comes from the scanner; the old camera button
            // is gone and supporting photos still use the normal camera.
            expect(find.text('Scan paper $kind'), findsOneWidget);
            expect(find.text('Take paper $kind photo'), findsNothing);
            expect(
              find.text('Add supporting photo'),
              findsNWidgets(isTicket ? 1 : 0),
            );
            tester
                .widget<ScanPaperBtn>(find.byType(ScanPaperBtn))
                .onPhotoAdded(paper);
            for (final control in tester.widgetList<AddPhotoEvidenceBtn>(
              find.byType(AddPhotoEvidenceBtn),
            )) {
              control.onPhotoAdded(evidence);
            }
            await flush(tester);
            expect(find.text('Rescan paper $kind'), findsOneWidget);
            expect(find.text('Scan paper $kind'), findsNothing);
          }
          // The copy-to-paper card is fed from this page: the confirmed
          // person, the place field, the chosen ordinance, the fine and the
          // signed-in enforcer.
          expect(
            copyCard(tester),
            type == ViolationType.ticket
                ? {
                    'NAME:': 'Juan Dela Cruz',
                    'ADDRESS:': '31 Synthetic Market Lane',
                    'ORDINANCE:':
                        'tick OTHERS, write:\n'
                        'Ord. No. 123 Series of 2026 series of 2026, '
                        'Sec. 69 – Proper Waste Disposal',
                    'FINE/PENALTIES:': 'tick OTHERS, write Php 100.00',
                    'PLACE:': 'Fish aisle near F-014',
                    'NAME & SIGNATURE OF APPREHENDING OFFICER:':
                        'Test Enforcer',
                  }
                : {
                    'Pangalan:': 'Juan Dela Cruz',
                    'Lugar:': 'Fish aisle near F-014',
                    'Ordinansa Blg.:':
                        'Ord. No. 123 Series of 2026, Serye: 2026\n'
                        'Sec. 69 – Proper Waste Disposal',
                    'Market Enforcer:': 'Test Enforcer',
                  },
          );
          await tester.ensureVisible(formAction());
          await tester.tap(formAction());
          await tester.pump();
          expect(find.text('Description is required.'), findsWidgets);
          expect(find.byType(NewInspectionPreviewPage), findsNothing);
          await tester.enterText(
            find.byKey(const ValueKey('inspection-description')),
            'Keep the stall and surroundings clean.',
          );
          await tester.ensureVisible(formAction());
          final nextButton = tester
              .widget<AppPrimaryButton>(formAction())
              .onPressed!;
          nextButton();
          nextButton();
          await flush(tester);
          expect(router.state.uri.path, '/inspection/new/preview');
          expect(find.byType(NewInspectionPreviewPage), findsOneWidget);
          final data = tester
              .widget<NewInspectionPreviewPage>(
                find.byType(NewInspectionPreviewPage),
              )
              .formData;
          expect(data.description, 'Keep the stall and surroundings clean.');
          expect(data.vendorSummary.id, 12);
          expect(data.ordinances.single.id, 1);
          expect(data.ticketType, type);
          expect(data.personId, 31);
          expect(data.issuePlace, 'Fish aisle near F-014');
          expect(data.evidences?.length, type == ViolationType.ticket ? 1 : 0);
          expect(data.paperTicketPhoto, isNotNull);
          if (type == ViolationType.ticket) {
            expect(data.evidences!.single.path, evidence.path);
          }
          expect(saveRequests, 0);

          router.pop();
          await flush(tester);
          expect(find.byType(AddNewInspectionPage), findsOneWidget);
          expect(
            tester
                .widget<TextFormField>(
                  find.byKey(const ValueKey('inspection-description')),
                )
                .controller!
                .text,
            data.description,
          );
          expect(tester.widget<AppPrimaryButton>(formAction()).label, 'Next');
          await tester.ensureVisible(formAction());
          await tester.tap(formAction());
          await flush(tester);
          if (type == ViolationType.ticket) {
            final submit = find.byWidgetPredicate(
              (widget) =>
                  widget is AppPrimaryButton && widget.label == 'Submit Ticket',
            );
            expect(tester.widget<AppPrimaryButton>(submit).onPressed, isNull);
            await tester.ensureVisible(find.text('Verify ticket'));
            await tester.tap(find.text('Verify ticket'));
            await flush(tester);
            expect(
              tester.widget<AppPrimaryButton>(submit).onPressed,
              isNotNull,
            );
          }
          if (type == ViolationType.ticket) {
            for (final field in ['paper-reference', 'issue-place']) {
              router.pop();
              await flush(tester);
              final value = field == 'paper-reference'
                  ? '000457'
                  : 'Fish aisle near F-015';
              final input = find.byKey(ValueKey(field));
              await tester.ensureVisible(input);
              await tester.enterText(input, value);
              await tester.pump();
              expect(
                copyCard(tester)['PLACE:'],
                field == 'issue-place'
                    ? 'Fish aisle near F-015'
                    : 'Fish aisle near F-014',
              );
              await tester.ensureVisible(formAction());
              await tester.tap(formAction());
              await flush(tester);
              final submit = find.byWidgetPredicate(
                (widget) =>
                    widget is AppPrimaryButton &&
                    widget.label == 'Submit Ticket',
              );
              expect(tester.widget<AppPrimaryButton>(submit).onPressed, isNull);
              final updated = tester
                  .widget<NewInspectionPreviewPage>(
                    find.byType(NewInspectionPreviewPage),
                  )
                  .formData;
              expect(
                field == 'paper-reference'
                    ? updated.paperReference
                    : updated.issuePlace,
                value,
              );
              await tester.ensureVisible(find.text('Verify ticket'));
              await tester.tap(find.text('Verify ticket'));
              await flush(tester);
              expect(
                tester.widget<AppPrimaryButton>(submit).onPressed,
                isNotNull,
              );
            }
          }
          await tester.ensureVisible(find.text('Submit ${type.value}'));
          await tester.tap(find.text('Submit ${type.value}'));
          await flush(tester);
          expect(find.byType(SubmitConfirmationBottomSheet), findsOneWidget);
          expect(
            saveRequests,
            0,
            reason: 'Only final confirmation may issue an inspection.',
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          // The catalog refresh writes through real Hive I/O. Close that box
          // outside the fake clock before the shared fixture's teardown.
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
          expect(
            cacheClosed,
            isTrue,
            reason: 'Real Hive close must complete before fixture teardown.',
          );
          await closingCache;
        },
      );
    }
  }
}
