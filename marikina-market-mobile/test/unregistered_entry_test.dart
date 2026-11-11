import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_hive_model.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/market_section.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/verify_inspection_input.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/vendor_summary.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_event.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_state.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/unregistered_section_banner.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/violator_info_card.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/person_identity_review.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/preview/violator_info_section.dart';

import 'features/auth/data/login_mobile_contract_test.dart' show reply;
import 'features/tickets/presentation/person_verification_flow_test.dart'
    show BoundaryImageCompressor;
import 'inspection_list_ui_test.dart' show listBloc;
import 'inspection_preview_navigation_test.dart' show flush, vendor;

// Faster entry B2: the enforcer enters an unregistered vendor on the phone by
// choosing a market section instead of finding a business. Sections and
// requests below are synthetic; the expected values are worked out by hand.

// The office's list: one section is switched off and must never be offered.
final sectionList = [
  {
    'id': 5,
    'name': 'Meat Section',
    'description': 'Meat',
    'is_active': true,
    'vendor_count': 12,
  },
  {
    'id': 6,
    'name': 'Closed Section',
    'description': 'Switched off',
    'is_active': false,
    'vendor_count': 0,
  },
  {
    'id': 7,
    'name': 'Vegetable Section',
    'description': 'Vegetables',
    'is_active': true,
    'vendor_count': 30,
  },
];

const meat = MarketSection(id: 5, name: 'Meat Section');

VerifyInspectionInput verifyInput({int? vendorId, int? marketSectionId}) =>
    VerifyInspectionInput(
      vendorId: vendorId,
      marketSectionId: marketSectionId,
      personId: 31,
      paperViolatorName: 'Juan Cruz',
      paperReference: '000456',
      issuePlace: 'Near gate 2',
      description: 'Aisle blocked',
      ordinanceIds: [1],
      penaltyType: PenaltyType.cashFine,
      evidenceCount: 2,
      paperTicketPhotoCount: 1,
      supportingEvidenceCount: 1,
    );

Future<void> showCard(
  WidgetTester tester,
  InspectionBloc bloc, {
  ValueChanged<VendorSummary>? onVendor,
  ValueChanged<MarketSection>? onSection,
}) async {
  var unregistered = false;
  tester.view.physicalSize = const Size(390, 1600);
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
            child: StatefulBuilder(
              builder: (context, setState) => ViolatorInfoCard(
                isUnregistered: unregistered,
                onKindChanged: (value) => setState(() => unregistered = value),
                onVendorSelected: onVendor ?? (_) {},
                onSectionSelected: onSection ?? (_) {},
                errorMessage: null,
              ),
            ),
          ),
        ),
      ),
    ),
  );
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

  group('market sections from the office list', () {
    test(
      'only switched-on sections are offered, in the office order',
      () async {
        final paths = <String>[];
        final bloc = await listBloc((options) async {
          paths.add(options.path);
          return reply(options, sectionList);
        });
        final loaded = bloc.stream.firstWhere(
          (state) => state is MarketSectionsLoaded,
        );
        bloc.add(MarketSectionsRequested());
        final state = await loaded as MarketSectionsLoaded;
        expect(paths, ['/marketsection']);
        expect(state.sections.map((section) => section.id), [5, 7]);
        expect(state.sections.map((section) => section.name), [
          'Meat Section',
          'Vegetable Section',
        ]);
      },
    );

    test('a failed request is reported so the enforcer can retry', () async {
      final bloc = await listBloc((options) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      });
      final failed = bloc.stream.firstWhere(
        (state) => state is MarketSectionsError,
      );
      bloc.add(MarketSectionsRequested());
      expect(
        (await failed as MarketSectionsError).message,
        'No internet connection. Please try again.',
      );
    });
  });

  group('requests without a business', () {
    test('verify sends the market section and no business', () async {
      final bodies = <Map<String, Object?>>[];
      final bloc = await listBloc((options) async {
        bodies.add(Map<String, Object?>.from(options.data as Map));
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      });
      bloc.add(
        InspectionVerificationRequested(verifyInput(marketSectionId: 5)),
      );
      await bloc.stream.firstWhere(
        (state) => state is InspectionVerificationError,
      );
      expect(bodies.single['vendor_id'], isNull);
      expect(bodies.single['market_section_id'], 5);
    });

    test('verify for a registered business sends no market section', () async {
      final bodies = <Map<String, Object?>>[];
      final bloc = await listBloc((options) async {
        bodies.add(Map<String, Object?>.from(options.data as Map));
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      });
      bloc.add(InspectionVerificationRequested(verifyInput(vendorId: 12)));
      await bloc.stream.firstWhere(
        (state) => state is InspectionVerificationError,
      );
      expect(bodies.single['vendor_id'], 12);
      expect(bodies.single['market_section_id'], isNull);
    });

    test('saving sends the market section and leaves out the business', () async {
      final original = FlutterImageCompressPlatform.instance;
      FlutterImageCompressPlatform.instance = BoundaryImageCompressor();
      addTearDown(() => FlutterImageCompressPlatform.instance = original);
      final folder = await Directory.systemTemp.createTemp('b2-save-');
      addTearDown(() => folder.delete(recursive: true));
      final photo = await File('${folder.path}/paper.png').writeAsBytes(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a9ZkAAAAASUVORK5CYII=',
        ),
      );
      final fields = <MapEntry<String, String>>[];
      final bloc = await listBloc((options) async {
        fields.addAll((options.data as FormData).fields);
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      });
      bloc.add(
        NewInspectionSubmitted(
          personId: 31,
          paperViolatorName: 'Juan Cruz',
          paperTicketPhoto: XFile(photo.path),
          issuePlace: 'Near gate 2',
          vendorId: null,
          enforcerId: 7,
          marketSectionId: 5,
          ticketType: ViolationType.warning,
          ordinanceIds: [1],
          penaltyType: PenaltyType.cashFine,
          communityServiceHours: null,
          description: 'Keep the aisle clear.',
          primaryCategory: [],
          evidences: null,
        ),
      );
      await bloc.stream.firstWhere(
        (state) => state is InspectionSubmitConnectionError,
      );
      final sent = Map.fromEntries(fields);
      expect(sent['market_section_id'], '5');
      expect(sent['issue_place'], 'Near gate 2');
      expect(sent.containsKey('vendor_id'), isFalse);
    });

    test('saving needs a business or a market section', () async {
      var requests = 0;
      final bloc = await listBloc((options) async {
        requests++;
        throw StateError('Nothing may be sent without a business or section.');
      });
      bloc.add(
        NewInspectionSubmitted(
          personId: 31,
          paperViolatorName: 'Juan Cruz',
          paperTicketPhoto: XFile('paper.png'),
          issuePlace: 'Near gate 2',
          vendorId: null,
          enforcerId: 7,
          marketSectionId: 0,
          ticketType: ViolationType.warning,
          ordinanceIds: [1],
          penaltyType: PenaltyType.cashFine,
          communityServiceHours: null,
          description: 'Keep the aisle clear.',
          primaryCategory: [],
          evidences: null,
        ),
      );
      final error =
          await bloc.stream.firstWhere(
                (state) => state is InspectionSubmitError,
              )
              as InspectionSubmitError;
      expect(
        error.message,
        'Confirm the person and business for this warning.',
      );
      expect(requests, 0);
    });

    test('the fine and the warning check work without a business', () async {
      final bodies = <String, Map<String, Object?>>{};
      final bloc = await listBloc((options) async {
        bodies[options.path] = Map<String, Object?>.from(options.data as Map);
        return options.path == '/enforcer/tickets/warning-check'
            ? reply(options, [])
            : reply(options, {
                'total_payment_amount': 0,
                'highest_severity': 'Minor',
                'breakdown': [],
              });
      });
      final fine = bloc.stream.firstWhere(
        (state) => state is FineSummaryLoaded,
      );
      bloc.add(FineSummaryRequested([1], null, personId: 31));
      await fine;
      final warning = bloc.stream.firstWhere(
        (state) => state is WarningOrdinanceCheckLoaded,
      );
      bloc.add(WarningOrdinanceCheckRequested([1], null, personId: 31));
      await warning;
      expect(bodies['/enforcer/tickets/fine-summary']!['person_id'], 31);
      expect(bodies['/enforcer/tickets/fine-summary']!['vendor_id'], isNull);
      expect(bodies['/enforcer/tickets/warning-check']!['person_id'], 31);
      expect(bodies['/enforcer/tickets/warning-check']!['vendor_id'], isNull);
    });
  });

  group('Registered / Unregistered choice', () {
    testWidgets('starts on Registered: search only, no QR scanning', (
      tester,
    ) async {
      final paths = <String>[];
      final bloc = await tester.runAsync(
        () => listBloc((options) async {
          paths.add(options.path);
          return reply(options, sectionList);
        }),
      );
      await showCard(tester, bloc!);
      expect(find.text('Registered'), findsOneWidget);
      expect(find.text('Unregistered'), findsOneWidget);
      expect(find.text('Search business'), findsOneWidget);
      expect(find.text('Scan QR Code'), findsNothing);
      expect(find.text('Search for a registered business.'), findsOneWidget);
      expect(find.text('Meat Section'), findsNothing);
      expect(paths, isEmpty);
    });

    testWidgets('Unregistered lists the active sections; one tap picks one', (
      tester,
    ) async {
      final bloc = await tester.runAsync(
        () => listBloc((options) async => reply(options, sectionList)),
      );
      MarketSection? picked;
      await showCard(tester, bloc!, onSection: (section) => picked = section);
      await tester.tap(find.text('Unregistered'));
      await flush(tester);
      expect(find.text('Search business'), findsNothing);
      expect(find.text('Market section'), findsOneWidget);
      expect(find.text('Meat Section'), findsOneWidget);
      expect(find.text('Vegetable Section'), findsOneWidget);
      expect(find.text('Closed Section'), findsNothing);
      await tester.tap(find.text('Meat Section'));
      await tester.pump();
      expect(picked?.id, 5);
      expect(picked?.name, 'Meat Section');
    });

    testWidgets('a section list that cannot load can be retried', (
      tester,
    ) async {
      var calls = 0;
      final bloc = await tester.runAsync(
        () => listBloc((options) async {
          if (++calls == 1) {
            throw DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
            );
          }
          return reply(options, sectionList);
        }),
      );
      await showCard(tester, bloc!);
      await tester.tap(find.text('Unregistered'));
      await flush(tester);
      expect(
        find.text('No internet connection. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Meat Section'), findsNothing);
      await tester.tap(find.text('Retry'));
      await flush(tester);
      expect(calls, 2);
      expect(find.text('Meat Section'), findsOneWidget);
    });

    testWidgets(
      'with no active section the enforcer is told to ask the office',
      (tester) async {
        final bloc = await tester.runAsync(
          () => listBloc((options) async => reply(options, [sectionList[1]])),
        );
        await showCard(tester, bloc!);
        await tester.tap(find.text('Unregistered'));
        await flush(tester);
        expect(
          find.text('No active market sections. Ask the office to add one.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('going back to Registered shows the search again', (
      tester,
    ) async {
      final bloc = await tester.runAsync(
        () => listBloc((options) async => reply(options, sectionList)),
      );
      await showCard(tester, bloc!);
      await tester.tap(find.text('Unregistered'));
      await flush(tester);
      await tester.tap(find.text('Registered'));
      await flush(tester);
      expect(find.text('Search business'), findsOneWidget);
      expect(find.text('Meat Section'), findsNothing);
    });
  });

  group('screens that name the business', () {
    testWidgets(
      'the banner names the vendor as unregistered with the section',
      (tester) async {
        var changed = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: UnregisteredSectionBanner(
                section: meat,
                onChangeSection: () => changed++,
              ),
            ),
          ),
        );
        expect(find.text('Unregistered vendor'), findsOneWidget);
        expect(find.text('Meat Section'), findsOneWidget);
        await tester.tap(find.text('Change section'));
        expect(changed, 1);
      },
    );

    testWidgets('no people list and no owner without a business', (
      tester,
    ) async {
      final paths = <String>[];
      final bloc = await tester.runAsync(
        () => listBloc((options) async {
          paths.add(options.path);
          return reply(options, []);
        }),
      );
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc!,
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: SingleChildScrollView(
                child: PersonIdentityReview(vendor: null, onChanged: (_, _) {}),
              ),
            ),
          ),
        ),
      );
      await flush(tester);
      expect(paths, isEmpty);
      expect(find.textContaining('Owner:'), findsNothing);
      expect(find.text('Add helper or another person'), findsOneWidget);
      expect(find.text('Check possible matches'), findsOneWidget);
    });

    testWidgets(
      'the review page says Unregistered vendor, with no business fields',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(
              body: SingleChildScrollView(
                child: ViolatorInfoSection(vendor: null, isTicket: true),
              ),
            ),
          ),
        );
        expect(find.text('Unregistered vendor'), findsOneWidget);
        expect(find.text('TRADE NAME:'), findsNothing);
        expect(find.text('REGISTERED OWNER:'), findsNothing);
        expect(find.text('STALL/UNIT NO:'), findsNothing);
        expect(
          find.textContaining('Verify to review the business'),
          findsNothing,
        );
      },
    );

    testWidgets('the review page still shows the business when there is one', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: ViolatorInfoSection(vendor: vendor, isTicket: true),
            ),
          ),
        ),
      );
      expect(find.text('Unregistered vendor'), findsNothing);
      expect(find.text('Synthetic Market Goods'), findsOneWidget);
    });
  });
}
