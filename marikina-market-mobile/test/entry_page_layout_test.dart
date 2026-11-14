import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:marikina_market_mobile/core/di/dependency_injection.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/auth/data/models/user_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_hive_model.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/vendor_summary.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/business_type.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_state.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/pages/add_new_inspection_page.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/bottom_sheets/select_ordinance_bottom_sheet.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/copy_to_paper_card.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/unregistered_section_banner.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/vendor_summary_banner.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/violator_info_card.dart';

import 'features/auth/data/login_mobile_contract_test.dart'
    show profileResponse, reply;
import 'features/tickets/data/models/ordinance_model_test.dart'
    show ordinanceResponse;
import 'inspection_list_ui_test.dart' show listBloc;
import 'inspection_preview_navigation_test.dart' show flush;
import 'unregistered_entry_test.dart' show sectionList;
import 'violator_picker_test.dart' show inReview, owner;

// The entry page layout: a bare start screen, a compact banner for the chosen
// business or section, and three labelled groups. The network is fake and
// every expected text and order is worked out by hand.

const bertsFish = VendorSummary(
  id: 12,
  username: null,
  type: BusinessType.public,
  businessAccountNumber: 'TEST-12',
  stallNumber: '12',
  tradeName: "Bert's Fish",
  lastName: 'Vendor',
  firstName: 'Synthetic',
  middleName: null,
  address: 'Synthetic Street, Marikina',
  marketSectionId: 1,
  marketSectionName: 'Dry Goods Section',
);

const bertsFishNoStall = VendorSummary(
  id: 12,
  username: null,
  type: BusinessType.public,
  businessAccountNumber: 'TEST-12',
  stallNumber: null,
  tradeName: "Bert's Fish",
  lastName: 'Vendor',
  firstName: 'Synthetic',
  middleName: null,
  address: 'Synthetic Street, Marikina',
  marketSectionId: 1,
  marketSectionName: 'Dry Goods Section',
);

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

  Future<void> openPage(
    WidgetTester tester, {
    double width = 390,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final bloc = await tester.runAsync(
      () => listBloc((options) async {
        switch (options.path) {
          case '/vendor/12/owner-person':
            return reply(options, owner);
          case '/vendor/12/people':
            return reply(options, []);
          case '/marketsection':
            return reply(options, sectionList);
          case '/ordinance':
            return reply(options, [ordinanceResponse]);
          case '/enforcer/tickets/warning-check':
            return reply(options, []);
          case '/ordinance/shortcuts':
            return reply(options, const {
              'person_ordinance_ids': <int>[],
              'my_recent_ordinance_ids': <int>[],
              'most_violated_ordinance_ids': <int>[],
            });
          default:
            throw DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
            );
        }
      }),
    );
    // The ordinance sheet makes its own bloc from the same fake network.
    final template = bloc!;
    sl.registerFactory<InspectionBloc>(
      () => InspectionBloc(
        matchPeopleUseCase: template.matchPeopleUseCase,
        createPersonUseCase: template.createPersonUseCase,
        getPersonHistoryUseCase: template.getPersonHistoryUseCase,
        loadInspectionListUseCase: template.loadInspectionListUseCase,
        loadOrdinancesUseCase: template.loadOrdinancesUseCase,
        getMarketSectionsUseCase: template.getMarketSectionsUseCase,
        searchBusinessesUseCase: template.searchBusinessesUseCase,
        getOrdinanceShortcutsUseCase: template.getOrdinanceShortcutsUseCase,
        getBusinessPeopleUseCase: template.getBusinessPeopleUseCase,
        getOwnerPersonUseCase: template.getOwnerPersonUseCase,
        addOwnerPersonUseCase: template.addOwnerPersonUseCase,
        getFineSummaryUseCase: template.getFineSummaryUseCase,
        checkWarningOrdinancesUseCase: template.checkWarningOrdinancesUseCase,
        saveInspectionTicketUseCase: template.saveInspectionTicketUseCase,
      ),
    );
    await tester.pumpWidget(
      BlocProvider.value(
        value: template,
        child: MaterialApp(
          theme: AppTheme.light,
          home: AddNewInspectionPage(
            user: UserModel.fromJson(profileResponse).toEntity(),
          ),
        ),
      ),
    );
    await flush(tester);
    // Close the catalog cache outside the fake clock, also when a test fails
    // half way; otherwise the shared teardown waits for 10 minutes.
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
  }

  Future<void> chooseBusiness(WidgetTester tester, VendorSummary vendor) async {
    tester
        .widget<ViolatorInfoCard>(find.byType(ViolatorInfoCard))
        .onVendorSelected(vendor);
    await flush(tester);
  }

  Future<void> chooseSection(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Unregistered'));
    await tester.tap(find.text('Unregistered'));
    await flush(tester);
    await tester.ensureVisible(find.text('Meat Section'));
    await tester.tap(find.text('Meat Section'));
    await flush(tester);
  }

  Future<void> chooseType(WidgetTester tester, ViolationType type) async {
    await tester.ensureVisible(find.text(type.value));
    await tester.tap(find.text(type.value));
    await flush(tester);
  }

  // Chooses the business owner as the violator and one ordinance, so the
  // copy-to-paper card has everything it needs for a warning.
  Future<void> chooseOwnerAndOrdinance(WidgetTester tester) async {
    await tester.ensureVisible(inReview(find.text('Synthetic Vendor')));
    await tester.tap(inReview(find.text('Synthetic Vendor')));
    await tester.pump();
    await tester.ensureVisible(find.text('Select ordinance'));
    await tester.tap(find.text('Select ordinance'));
    await tester.pump();
    final sheetBloc = tester
        .element(find.byType(SelectOrdinanceBottomSheet))
        .read<InspectionBloc>();
    for (
      var attempt = 0;
      attempt < 100 &&
          sheetBloc.state is! OrdinanceSelectionLoaded &&
          sheetBloc.state is! OrdinanceSelectionError;
      attempt++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(sheetBloc.state, isA<OrdinanceSelectionLoaded>());
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

  // Runs the body while collecting every framework error (overflows
  // included), so none is missed. The normal handler comes back before any
  // failure is reported.
  Future<void> trackingErrors(
    Future<void> Function(List<String> errors) body,
  ) async {
    final errors = <String>[];
    final original = FlutterError.onError;
    // Written out on the spot: the widget is gone by the time it is read.
    FlutterError.onError = (details) =>
        errors.add(details.toString(minLevel: DiagnosticLevel.debug));
    try {
      await body(errors);
    } finally {
      FlutterError.onError = original;
    }
  }

  bool fromOwnerCard(String error) => error.contains('owner_person_card.dart');

  Finder inBanner(Finder finder) =>
      find.descendant(of: find.byType(VendorSummaryBanner), matching: finder);

  double top(WidgetTester tester, Finder finder) {
    expect(finder, findsOneWidget);
    return tester.getTopLeft(finder).dy;
  }

  group('start screen', () {
    testWidgets('1: the start screen keeps its heading, help text and card', (
      tester,
    ) async {
      await openPage(tester);
      expect(find.text('New Inspection'), findsOneWidget);
      expect(find.text('Registered'), findsOneWidget);
      expect(find.text('Unregistered'), findsOneWidget);
      expect(find.text('Search business'), findsOneWidget);
      expect(find.text('Inspection details'), findsOneWidget);
      expect(
        find.textContaining('Choose Registered or Unregistered'),
        findsOneWidget,
      );
      expect(find.text('Find Vendor'), findsOneWidget);
      expect(find.text('Search for a registered business.'), findsOneWidget);
      expect(find.text('Vendor information is required'), findsOneWidget);
      expect(
        find.text(
          'Please find the vendor to view details and create a record.',
        ),
        findsOneWidget,
      );
      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('1b: Unregistered keeps its help text and section chips', (
      tester,
    ) async {
      await openPage(tester);
      await tester.tap(find.text('Unregistered'));
      await flush(tester);
      expect(find.text('Meat Section'), findsOneWidget);
      expect(find.text('Search business'), findsNothing);
      expect(find.text('Inspection details'), findsOneWidget);
      expect(
        find.text('Choose the market section where the vendor was found'),
        findsOneWidget,
      );
      expect(find.text('Vendor information is required'), findsOneWidget);
      expect(
        find.text('Please choose the market section to create a record.'),
        findsOneWidget,
      );
    });
  });

  group('compact banner', () {
    testWidgets(
      '2: business card keeps its details and the Change Vendor button',
      (tester) async {
        await openPage(tester);
        await chooseBusiness(tester, bertsFish);
        expect(find.text("Bert's Fish"), findsOneWidget);
        expect(find.text('Account Number: TEST-12'), findsOneWidget);
        expect(find.textContaining('Business Account Number'), findsNothing);
        expect(
          find.text('Registered owner: Vendor, Synthetic'),
          findsOneWidget,
        );
        expect(find.text('12 • Dry Goods Section'), findsOneWidget);
        expect(inBanner(find.text('Change Vendor')), findsOneWidget);
        expect(find.text('Search business'), findsNothing);

        await tester.tap(inBanner(find.text('Change Vendor')));
        await flush(tester);
        expect(find.byType(VendorSummaryBanner), findsNothing);
        expect(find.text('Search business'), findsOneWidget);
        expect(find.text('Registered'), findsOneWidget);
      },
    );

    testWidgets('2b: without a stall the card says No stall assigned', (
      tester,
    ) async {
      await openPage(tester);
      await chooseBusiness(tester, bertsFishNoStall);
      expect(
        inBanner(find.text('No stall assigned • Dry Goods Section')),
        findsOneWidget,
      );
    });

    testWidgets('2c: unregistered banner has the same compact style', (
      tester,
    ) async {
      await openPage(tester);
      await chooseSection(tester);
      final banner = find.byType(UnregisteredSectionBanner);
      expect(
        find.descendant(of: banner, matching: find.text('Unregistered vendor')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: banner, matching: find.text('Meat Section')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: banner, matching: find.text('Change')),
        findsOneWidget,
      );
      expect(find.byTooltip('Change section'), findsOneWidget);
      expect(find.text('Change section'), findsNothing);

      await tester.tap(
        find.descendant(of: banner, matching: find.text('Change')),
      );
      await flush(tester);
      expect(banner, findsNothing);
      expect(find.text('Meat Section'), findsOneWidget);
    });
  });

  group('groups', () {
    testWidgets('3: ticket groups appear in order', (tester) async {
      await openPage(tester);
      await chooseBusiness(tester, bertsFish);
      await chooseType(tester, ViolationType.ticket);
      final order = [
        top(tester, find.text('Paper details')),
        top(tester, find.text('Control number')),
        top(tester, find.text('Issue place')),
        top(tester, find.text('Violator')),
        top(tester, find.text('Violation')),
        top(tester, find.text('Ordinance')),
        top(tester, find.text('Description')),
        top(tester, find.text('Paper copy')),
        top(tester, find.text('Paper ticket photo')),
        top(tester, find.text('Supporting evidence')),
        top(tester, find.text('Next')),
      ];
      for (var i = 1; i < order.length; i++) {
        expect(order[i], greaterThan(order[i - 1]), reason: 'position $i');
      }
      // No ALL CAPS headings or labels are left.
      for (final old in [
        'ISSUE PLACE',
        'DESCRIPTION',
        'ORDINANCE',
        'VIOLATION',
      ]) {
        expect(find.text(old), findsNothing, reason: old);
      }
    });

    testWidgets(
      '3b: warning groups appear in order, without a control number',
      (tester) async {
        await openPage(tester);
        await chooseBusiness(tester, bertsFish);
        expect(find.text('Control number'), findsNothing);
        final order = [
          top(tester, find.text('Paper details')),
          top(tester, find.text('Issue place')),
          top(tester, find.text('Violator')),
          top(tester, find.text('Violation')),
          top(tester, find.text('Ordinance')),
          top(tester, find.text('Description')),
          top(tester, find.text('Paper copy')),
          top(tester, find.text('Paper warning photo')),
          top(tester, find.text('Next')),
        ];
        for (var i = 1; i < order.length; i++) {
          expect(order[i], greaterThan(order[i - 1]), reason: 'position $i');
        }
      },
    );

    testWidgets('3c: a ready paper copy card does not touch the photo label', (
      tester,
    ) async {
      await openPage(tester);
      await chooseBusiness(tester, bertsFish);
      await chooseOwnerAndOrdinance(tester);
      expect(find.text('Copy these onto the paper warning'), findsOneWidget);
      final cardBottom = tester.getBottomLeft(find.byType(CopyToPaperCard)).dy;
      final labelTop = tester.getTopLeft(find.text('Paper warning photo')).dy;
      expect(
        labelTop - cardBottom,
        greaterThanOrEqualTo(AppTheme.inspectionSmallGap),
      );
    });

    testWidgets('3d: a warning with no Issue place says where to enter it', (
      tester,
    ) async {
      await openPage(tester);
      await chooseBusiness(tester, bertsFish);
      await tester.enterText(
        find.byKey(const ValueKey('warning-issue-place')),
        '',
      );
      await tester.ensureVisible(find.text('Next'));
      await tester.tap(find.text('Next'));
      await flush(tester);
      expect(find.text('Enter where the warning was issued.'), findsOneWidget);
    });

    testWidgets('4: warning has no control number and the same Issue place', (
      tester,
    ) async {
      await openPage(tester);
      await chooseBusiness(tester, bertsFish);
      expect(find.byKey(const ValueKey('paper-reference')), findsNothing);
      expect(find.text('Control number'), findsNothing);
      expect(find.text('Issue place'), findsOneWidget);
      expect(find.text('Paper warning photo'), findsOneWidget);
      expect(find.text('Supporting evidence'), findsNothing);
      TextField field(String key) => tester.widget<TextField>(
        find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(TextField),
        ),
      );
      final warningField = field('warning-issue-place');
      expect(find.byKey(const ValueKey('issue-place')), findsNothing);

      await chooseType(tester, ViolationType.ticket);
      expect(find.text('Issue place'), findsOneWidget);
      expect(find.byKey(const ValueKey('warning-issue-place')), findsNothing);
      final ticketField = field('issue-place');
      expect(warningField.decoration, ticketField.decoration);
      expect(warningField.maxLength, ticketField.maxLength);
      expect(warningField.minLines, ticketField.minLines);
      expect(warningField.maxLines, ticketField.maxLines);
      // The 0/500 counter is hidden on both.
      expect(ticketField.decoration!.counterText, '');
      expect(find.textContaining('/500'), findsNothing);
      expect(find.textContaining('/200'), findsNothing);
    });
  });

  group('buttons', () {
    for (final type in ViolationType.values) {
      testWidgets('5: ${type.value}, with the owner already a person record: '
          'Next is the only filled button', (tester) async {
        await openPage(tester);
        await chooseBusiness(tester, bertsFish);
        await chooseType(tester, type);
        final isTicket = type == ViolationType.ticket;
        expect(find.bySubtype<FilledButton>(), findsNothing);
        expect(find.bySubtype<ElevatedButton>(), findsOneWidget);
        expect(
          find.ancestor(
            of: find.text('Next'),
            matching: find.bySubtype<ElevatedButton>(),
          ),
          findsOneWidget,
        );
        for (final label in [
          isTicket ? 'Scan paper ticket' : 'Scan paper warning',
          if (isTicket) 'Add supporting photo',
          'Select ordinance',
        ]) {
          expect(
            find.ancestor(
              of: find.text(label),
              matching: find.bySubtype<OutlinedButton>(),
            ),
            findsOneWidget,
            reason: label,
          );
        }
      });
    }

    testWidgets(
      '5b: Cancel is a quiet full-width text button that asks first',
      (tester) async {
        await openPage(tester);
        await chooseBusiness(tester, bertsFish);
        final cancel = find.ancestor(
          of: find.text('Cancel'),
          matching: find.bySubtype<TextButton>(),
        );
        expect(cancel, findsOneWidget);
        expect(
          find.ancestor(
            of: find.text('Cancel'),
            matching: find.bySubtype<OutlinedButton>(),
          ),
          findsNothing,
        );
        await tester.ensureVisible(cancel);
        // 20 pixels of page padding on each side.
        expect(tester.getSize(cancel).width, 390 - 40);
        // Readable on the white page: at least 4.5 to 1 against white.
        final color = tester
            .widget<TextButton>(cancel)
            .style!
            .foregroundColor!
            .resolve({})!;
        expect(
          1.05 / (color.computeLuminance() + 0.05),
          greaterThanOrEqualTo(4.5),
        );

        await tester.tap(cancel);
        await tester.pump();
        expect(find.text('Discard Inspection?'), findsOneWidget);
        await tester.tap(find.text('Stay'));
        await tester.pump();
        expect(find.text('Discard Inspection?'), findsNothing);
        expect(find.byType(AddNewInspectionPage), findsOneWidget);
      },
    );
  });

  group('narrow screen, large text', () {
    testWidgets('6: start screen fits 320 px at 2x text', (tester) async {
      await openPage(tester, width: 320, textScale: 2);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Unregistered'));
      await tester.tap(find.text('Unregistered'));
      await flush(tester);
      expect(find.text('Meat Section'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final type in ViolationType.values) {
      testWidgets('6: ${type.value} form fits 320 px at 2x text, with errors', (
        tester,
      ) async {
        await openPage(tester, width: 320, textScale: 2);
        expect(tester.takeException(), isNull);
        await trackingErrors((errors) async {
          await chooseBusiness(tester, bertsFish);
          // The owner has finished loading. Only the owner card's "Loading
          // owner…" row (slice 1, not part of this layout) is too wide for
          // that one loading frame, so only an error from that file is
          // allowed.
          expect(inReview(find.text('Synthetic Vendor')), findsOneWidget);
          expect(errors.where((error) => !fromOwnerCard(error)), isEmpty);
          errors.clear();
          await chooseType(tester, type);
          // Next shows every missing-field message at once.
          await tester.ensureVisible(find.text('Next'));
          await tester.tap(find.text('Next'));
          await flush(tester);
          expect(find.text('Description is required.'), findsWidgets);
          expect(errors, isEmpty);
        });
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('6: unregistered form fits 320 px at 2x text', (tester) async {
      await openPage(tester, width: 320, textScale: 2);
      expect(tester.takeException(), isNull);
      await trackingErrors((errors) async {
        await chooseSection(tester);
        expect(find.byType(UnregisteredSectionBanner), findsOneWidget);
        expect(errors, isEmpty);
      });
      expect(tester.takeException(), isNull);
    });
  });
}
