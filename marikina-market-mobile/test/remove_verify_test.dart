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
import 'package:marikina_market_mobile/core/shared/presentation/widgets/app_primary_btn.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/fine_summary_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_hive_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_model.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/inspection_form_data.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_state.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/pages/new_inspection_preview_page.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/preview/duplicate_ticket_dialog.dart';

import 'features/tickets/data/models/ordinance_model_test.dart'
    show ordinanceResponse;
import 'features/tickets/presentation/person_verification_flow_test.dart'
    show BoundaryImageCompressor;
import 'features/tickets/presentation/up_to_assessment_flow_test.dart'
    show calculation;
import 'inspection_list_ui_test.dart' show listBloc;
import 'inspection_preview_navigation_test.dart' show flush, vendor;

// The preview of a new ticket has no Verify step: Submit is on when the ticket
// is complete, nothing is sent before Submit, and the server checks again when
// Submit is pressed. The network is fake; the tests read which requests the
// phone made and what they carried.

const needFines =
    'Complete the assessed fines and confirm the applicable penalty '
    'configuration before submitting.';
const needNumber = 'Enter the control number and issue place.';
const needPhotos =
    'One paper ticket photo and at least one supporting photo are required '
    'for tickets.';
const usedNumber =
    'A citation with this control number already exists. Review the control '
    'number before submitting.';

const fixedFine = <String, Object?>{
  'total_payment_amount': 500,
  'highest_severity': 'Minor',
  'breakdown': [
    {
      'ordinance_id': 1,
      'ordinance_no': '011',
      'section': '66',
      'offense_number': 1,
      'payment_amount': 500,
      'fine_kind': 'Fixed',
      'severity': 'Minor',
      'is_duplicate': false,
    },
  ],
};

DioException refused(
  RequestOptions options,
  int status,
  Map<String, Object?> body,
) => DioException(
  requestOptions: options,
  type: DioExceptionType.badResponse,
  response: Response<Object?>(
    requestOptions: options,
    statusCode: status,
    data: body,
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(OrdinanceHiveModelAdapter());
    }
  });
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  late XFile photo;

  // Opens the preview of a ticket (or warning) and returns what the fake
  // server was asked, in order.
  Future<(InspectionBloc, List<RequestOptions>)> openPreview(
    WidgetTester tester, {
    String? paperReference = '000456',
    bool paperPhoto = true,
    bool supportingPhoto = true,
    Map<String, Object?> fine = fixedFine,
    ViolationType type = ViolationType.ticket,
    Future<Response<Object?>> Function(RequestOptions)? respond,
  }) async {
    final original = FlutterImageCompressPlatform.instance;
    FlutterImageCompressPlatform.instance = BoundaryImageCompressor();
    addTearDown(() => FlutterImageCompressPlatform.instance = original);
    final folder = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('remove-verify-'),
    ))!;
    final file = (await tester.runAsync(
      () => File('${folder.path}/synthetic.png').writeAsBytes(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a9ZkAAAAASUVORK5CYII=',
        ),
      ),
    ))!;
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      await tester.runAsync(() => folder.delete(recursive: true));
    });
    photo = XFile(file.path);
    final requests = <RequestOptions>[];
    final bloc = (await tester.runAsync(
      () => listBloc((options) async {
        requests.add(options);
        if (respond == null) {
          throw StateError('Unexpected request: ${options.path}');
        }
        return respond(options);
      }),
    ))!;
    addTearDown(bloc.close);
    final isTicket = type == ViolationType.ticket;
    final draft = InspectionFormData(
      vendorSummary: vendor,
      enforcerId: 7,
      personId: 31,
      personFullName: 'Juan Dela Cruz',
      paperViolatorName: 'Juan Cruz',
      paperReference: isTicket ? paperReference : null,
      issuePlace: 'Fish aisle near F-014',
      description: 'Market identification card not displayed',
      ticketType: type,
      penaltyType: PenaltyType.cashFine,
      communityServiceHrs: null,
      fineSummary: FineSummaryModel.fromJson(fine).toEntity(),
      ordinances: [OrdinanceModel.fromJson(ordinanceResponse).toEntity()],
      paperTicketPhoto: paperPhoto ? photo : null,
      evidences: isTicket && supportingPhoto ? [photo] : [],
    );
    tester.view.physicalSize = const Size(400, 2400);
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
    return (bloc, requests);
  }

  Finder button(String label) =>
      find.byWidgetPredicate((w) => w is AppPrimaryButton && w.label == label);
  bool isOn(WidgetTester tester, Finder finder) =>
      tester.widget<AppPrimaryButton>(finder).onPressed != null;

  // Opens the confirmation sheet and confirms, as the enforcer does.
  Future<void> pressSubmit(WidgetTester tester, InspectionBloc bloc) async {
    final submit = button('Submit Ticket');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await flush(tester);
    final confirm = find.byWidgetPredicate(
      (w) => w is AppPrimaryButton && w.label.startsWith('Issue ticket '),
    );
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await flush(tester);
  }

  testWidgets('the preview of a new ticket has no Verify ticket button', (
    tester,
  ) async {
    await openPreview(tester);

    expect(find.text('Verify ticket'), findsNothing);
    expect(find.textContaining('Verify again'), findsNothing);
    expect(find.textContaining('Verified'), findsNothing);
    expect(button('Submit Ticket'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'Submit is on for a complete ticket and says nothing is missing',
    (tester) async {
      await openPreview(tester);

      expect(isOn(tester, button('Submit Ticket')), isTrue);
      expect(find.text(needFines), findsNothing);
      expect(find.text(needNumber), findsNothing);
      expect(find.text(needPhotos), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('Submit is off with a line for each missing control number', (
    tester,
  ) async {
    await openPreview(tester, paperReference: '  ');

    expect(isOn(tester, button('Submit Ticket')), isFalse);
    expect(find.text(needNumber), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Submit is off with a line when the paper photo is missing', (
    tester,
  ) async {
    await openPreview(tester, paperPhoto: false);

    expect(isOn(tester, button('Submit Ticket')), isFalse);
    expect(find.text(needPhotos), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'Submit is off with a line when the supporting photo is missing',
    (tester) async {
      await openPreview(tester, supportingPhoto: false);

      expect(isOn(tester, button('Submit Ticket')), isFalse);
      expect(find.text(needPhotos), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('an up-to fine without an amount keeps Submit off until it is '
      'filled in', (tester) async {
    await openPreview(tester, fine: calculation());

    expect(isOn(tester, button('Submit Ticket')), isFalse);
    expect(find.text(needFines), findsOneWidget);

    final field = find.byKey(const ValueKey('assessed-fine-1'));
    await tester.ensureVisible(field);
    await tester.enterText(field, '500.00');
    await flush(tester);

    expect(isOn(tester, button('Submit Ticket')), isTrue);
    expect(find.text(needFines), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('nothing is sent to the server before Submit', (tester) async {
    final (_, requests) = await openPreview(tester, fine: calculation());

    final field = find.byKey(const ValueKey('assessed-fine-1'));
    await tester.ensureVisible(field);
    await tester.enterText(field, '500.00');
    await flush(tester);

    expect(requests, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('the Submit request carries no reviewed values', (tester) async {
    late (InspectionBloc, List<RequestOptions>) opened;
    opened = await openPreview(
      tester,
      respond: (options) async =>
          throw refused(options, 400, {'message': 'Stop here.'}),
    );
    final (bloc, requests) = opened;

    await pressSubmit(tester, bloc);

    final request = requests.single;
    expect(request.path, '/enforcer/tickets/new-inspection');
    final fields = Map.fromEntries((request.data as FormData).fields);
    expect(fields.keys, isNot(contains('reviewed_calculation')));
    expect(fields.keys, isNot(contains('reviewed_business_snapshot')));
    expect(fields['paper_reference'], '000456');
    expect(fields['vendor_id'], '12');
    expect(fields['person_id'], '31');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'a refusal shows the server message and Submit can be used again',
    (tester) async {
      late (InspectionBloc, List<RequestOptions>) opened;
      opened = await openPreview(
        tester,
        respond: (options) async => throw refused(options, 409, {
          'title': 'Conflict',
          'message': usedNumber,
        }),
      );
      final (bloc, requests) = opened;

      await pressSubmit(tester, bloc);

      expect(bloc.state, isA<InspectionSubmitError>());
      expect(find.text(usedNumber), findsAtLeastNWidgets(1));
      expect(isOn(tester, button('Submit Ticket')), isTrue);
      await pressSubmit(tester, bloc);
      expect(requests, hasLength(2));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('a duplicate for today opens the duplicate dialog and Submit '
      'stays usable', (tester) async {
    late (InspectionBloc, List<RequestOptions>) opened;
    opened = await openPreview(
      tester,
      respond: (options) async => throw refused(options, 409, {
        'title': 'Duplicate Ordinances Today',
        'message':
            'This person already has an active citation for a selected '
            'ordinance today. Review the ordinances.',
        'duplicateOrdinances': [
          {'ordinance_id': 1, 'ordinance_no': '011', 'section': '66'},
        ],
      }),
    );
    final (bloc, _) = opened;

    await pressSubmit(tester, bloc);

    expect(bloc.state, isA<DuplicationConflictInspection>());
    expect(find.byType(DuplicateTicketDialog), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a lost connection during Submit still blocks a second Submit', (
    tester,
  ) async {
    late (InspectionBloc, List<RequestOptions>) opened;
    opened = await openPreview(
      tester,
      respond: (options) async => throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      ),
    );
    final (bloc, requests) = opened;

    await pressSubmit(tester, bloc);

    expect(bloc.state, isA<InspectionSubmitConnectionError>());
    expect(isOn(tester, button('Submit Ticket')), isFalse);
    expect(requests, hasLength(1));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('the warning preview is unchanged', (tester) async {
    await openPreview(tester, type: ViolationType.warning);

    expect(find.text('Verify ticket'), findsNothing);
    expect(
      find.text("The warning's control number is assigned when saved."),
      findsOneWidget,
    );
    expect(button('Submit Warning'), findsOneWidget);
    expect(isOn(tester, button('Submit Warning')), isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
