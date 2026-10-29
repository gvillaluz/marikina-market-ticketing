import 'dart:io';

import 'package:flutter/material.dart';
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
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/pages/add_new_inspection_page.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/pages/new_inspection_preview_page.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/add_photo_evidence_btn.dart';
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
  await tester.pumpAndSettle();
}

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
        Routes.vendorDashboard,
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
                case '/enforcer/tickets/verify':
                  return reply(options, {
                    'reviewed_calculation': 'reviewed-calculation',
                    'calculation': {
                      'total_payment_amount': 100,
                      'highest_severity': 'Minor',
                      'breakdown': [
                        {
                          'ordinance_id': 1,
                          'ordinance_no': ordinanceResponse['ordinance_no'],
                          'ordinance_code': 'MKT-001',
                          'payment_amount': 100,
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
                  return reply(options, []);
                case '/enforcer/tickets/fine-summary':
                  return reply(options, {
                    'total_payment_amount': 100,
                    'highest_severity': 'Minor',
                    'breakdown': [
                      {
                        'ordinance_id': 1,
                        'ordinance_no': ordinanceResponse['ordinance_no'],
                        'ordinance_code': 'MKT-001',
                        'payment_amount': 100,
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
          // Complete real Hive I/O outside the widget test's fake clock before
          // the form and selection sheet read the shared ordinance cache.
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
              searchVendorByStallUseCase:
                  templateBloc.searchVendorByStallUseCase,
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
          tester
              .widget<ViolatorInfoCard>(find.byType(ViolatorInfoCard))
              .onVendorSelected(vendor);
          await tester.pump();
          tester
              .widget<InspectionTypeToggle>(find.byType(InspectionTypeToggle))
              .onChange(type);
          await tester.pump();
          if (type == ViolationType.ticket) {
            expect(find.text('Paper reference'), findsOneWidget);
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
            final name = find.byWidgetPredicate(
              (widget) =>
                  widget is TextField &&
                  widget.decoration?.labelText == 'Paper violator name',
            );
            await tester.enterText(name, 'Juan Cruz');
            await tester.ensureVisible(find.text('Check possible matches'));
            await tester.tap(find.text('Check possible matches'));
            await flush(tester);
            await tester.ensureVisible(find.text('Confirm'));
            await tester.tap(find.text('Confirm'));
            await tester.pump();
          }
          await tester.ensureVisible(find.text('Select Ordinance'));
          await tester.tap(find.text('Select Ordinance'));
          await flush(tester);
          await tester.tap(
            find.text(
              'Ord No. ${ordinanceResponse['ordinance_no']}, Series of ${ordinanceResponse['series']}',
            ),
          );
          await tester.pump();
          await tester.tap(find.text('Confirm selection'));
          await flush(tester);
          XFile? evidence;
          if (type == ViolationType.ticket) {
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
            tester
                .widget<AddPhotoEvidenceBtn>(find.byType(AddPhotoEvidenceBtn))
                .onPhotoAdded(evidence);
            await flush(tester);
          }
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
          expect(data.evidences?.length, type == ViolationType.ticket ? 1 : 0);
          if (evidence != null) {
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
        },
      );
    }
  }
}
