import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/app_primary_btn.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/fine_summary_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_hive_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_model.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/fine_assessment.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/inspection_form_data.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/pages/new_inspection_preview_page.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/assessed_fine_field.dart';
import '../../../inspection_list_ui_test.dart' show listBloc;
import '../../../inspection_preview_navigation_test.dart' show vendor, flush;
import '../data/models/ordinance_model_test.dart' show ordinanceResponse;
import '../data/models/penalty_terms_contract_test.dart' show provisionalFine;

Map<String, Object?> calculation([double? amount, double cap = 1000]) => {
  'total_payment_amount': amount,
  'highest_severity': 'High',
  'allow_blood_donation': true,
  'allow_community_service': true,
  'breakdown': [
    {
      'ordinance_id': 1,
      'ordinance_no': '11',
      'section': '53',
      'payment_amount': amount,
      'severity': 'High',
      'offense_number': 1,
      'is_duplicate': false,
      'fine_kind': 'UpTo',
      'minimum_fine': 100,
      'maximum_fine': cap,
      'penalty_terms': 'Up to P1,000',
      'allow_blood_donation': true,
      'allow_community_service': true,
    },
  ],
};

void main() {
  setUpAll(() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(OrdinanceHiveModelAdapter());
    }
  });
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  testWidgets(
    'assessment field reflects a replaced draft without losing typing selection',
    (tester) async {
      final item = FineSummaryModel.fromJson(
        calculation(),
      ).toEntity().breakdownItems.single;
      Widget field(String value) => MaterialApp(
        home: Scaffold(
          body: AssessedFineField(item: item, value: value, onChanged: (_) {}),
        ),
      );
      await tester.pumpWidget(field('600'));
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        '600',
      );
      await tester.pumpWidget(field('100'));
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        '100',
      );
      await tester.enterText(find.byType(TextFormField), '125');
      final editor = tester.widget<EditableText>(find.byType(EditableText));
      editor.controller.selection = const TextSelection.collapsed(offset: 1);
      await tester.pumpWidget(field('125'));
      expect(editor.controller.selection.baseOffset, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('unconfirmed terms are visible and cannot be submitted', (
    tester,
  ) async {
    final bloc = (await tester.runAsync(
      () => listBloc((options) async {
        fail('An unconfirmed penalty must not reach the API.');
      }),
    ))!;
    final draft = InspectionFormData(
      vendorSummary: vendor,
      enforcerId: 7,
      enforcerName: 'Reyes, Ana',
      personId: 31,
      paperViolatorName: 'Synthetic Vendor',
      paperReference: 'S2-0002',
      issuePlace: 'Market aisle',
      description: 'Unconfirmed later offense',
      ticketType: ViolationType.ticket,
      penaltyType: PenaltyType.cashFine,
      communityServiceHrs: null,
      fineSummary: FineSummaryModel.fromJson(provisionalFine).toEntity(),
      ordinances: [
        OrdinanceModel.fromJson({...ordinanceResponse, 'id': 53}).toEntity(),
      ],
      evidences: null,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<InspectionBloc>.value(
          value: bloc,
          child: NewInspectionPreviewPage(formData: draft),
        ),
      ),
    );
    await flush(tester);
    expect(find.text('Second offense is not stated.'), findsOneWidget);
    final submit = find.byWidgetPredicate(
      (w) => w is AppPrimaryButton && w.label == 'Submit Ticket',
    );
    expect(tester.widget<AppPrimaryButton>(submit).onPressed, isNull);
    expect(find.text('₱0.00'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  for (final width in [280.0, 400.0, 390.0]) {
    testWidgets(
      'changing an UpTo amount turns Submit off outside the bounds at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final folder = (await tester.runAsync(
          () => Directory.systemTemp.createTemp('paper-assessed-flow-'),
        ))!;
        final photo = (await tester.runAsync(
          () => File('${folder.path}/paper.png').writeAsBytes(
            base64Decode(
              'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a9ZkAAAAASUVORK5CYII=',
            ),
          ),
        ))!;
        addTearDown(() => folder.delete(recursive: true));
        final requests = <String>[];
        final bloc = (await tester.runAsync(
          () => listBloc((options) async {
            requests.add(options.path);
            throw StateError('Nothing is sent before Submit.');
          }),
        ))!;
        addTearDown(bloc.close);
        final draft = InspectionFormData(
          vendorSummary: vendor,
          enforcerId: 7,
          enforcerName: 'Reyes, Ana',
          personId: 31,
          paperViolatorName: 'Synthetic Vendor',
          paperReference: 'S2-0001',
          issuePlace: 'Market aisle',
          description: 'Paper-assessed market obstruction',
          ticketType: ViolationType.ticket,
          penaltyType: PenaltyType.cashFine,
          communityServiceHrs: null,
          fineSummary: FineSummaryModel.fromJson(calculation()).toEntity(),
          fineAssessments: const [
            FineAssessment(ordinanceId: 1, assessedAmount: 100),
          ],
          ordinances: [
            OrdinanceModel.fromJson({
              ...ordinanceResponse,
              'severity': 'High',
              'warning_eligible': true,
            }).toEntity(),
          ],
          paperTicketPhoto: XFile(photo.path),
          evidences: [XFile(photo.path)],
        );
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                textScaler: TextScaler.linear(width == 280 ? 1.6 : 1),
              ),
              child: BlocProvider<InspectionBloc>.value(
                value: bloc,
                child: NewInspectionPreviewPage(formData: draft),
              ),
            ),
          ),
        );
        await flush(tester);
        final submit = find.byWidgetPredicate(
          (w) => w is AppPrimaryButton && w.label == 'Submit Ticket',
        );
        // The assessed amount that came with the draft is inside the bounds.
        expect(tester.widget<AppPrimaryButton>(submit).onPressed, isNotNull);
        final field = find.byKey(const ValueKey('assessed-fine-1'));
        await tester.ensureVisible(field);
        await tester.enterText(field, '99.99');
        await flush(tester);
        expect(tester.widget<AppPrimaryButton>(submit).onPressed, isNull);
        await tester.enterText(field, '1000.01');
        await flush(tester);
        expect(tester.widget<AppPrimaryButton>(submit).onPressed, isNull);
        await tester.enterText(field, '1000.00');
        await flush(tester);
        expect(tester.widget<AppPrimaryButton>(submit).onPressed, isNotNull);
        expect(requests, isEmpty);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
