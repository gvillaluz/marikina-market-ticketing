import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_state.dart';
import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/app_primary_btn.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_hive_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_model.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/inspection_form_data.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/pages/new_inspection_preview_page.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import '../../../inspection_list_ui_test.dart' show listBloc;
import '../../../inspection_preview_navigation_test.dart' show vendor, flush;
import '../../auth/data/login_mobile_contract_test.dart' show reply;
import '../data/models/ordinance_model_test.dart' show ordinanceResponse;
import 'person_verification_flow_test.dart' show BoundaryImageCompressor;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ticket_detail_model.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/violator_detail_section.dart';

const snapshot = <String, Object?>{
  'business_account_number': 'SNAP-001',
  'business_name': 'Market Fish A',
  'registered_owner_name': 'Owner A',
  'business_type': 'Public',
  'stall_number': 'F-14',
  'market_section_name': 'Fish A',
  'business_address': '14 Market Lane',
};
Map<String, Object?> record(Object? saved) => {
  'ticket_id': 1,
  'enforcer_id': 3,
  'vendor_id': 1,
  'type': 'Ticket',
  'business_type': 'Public',
  'business_account_number': 'CURRENT-B',
  'business_name': 'Business B',
  'first_name': 'Current',
  'last_name': 'Owner B',
  'registered_owner_name': 'Current Owner B',
  'address': 'Current address B',
  'violations': <Object?>[],
  'issued_at': '2026-10-30T00:00:00Z',
  'market_section_name': 'Current Section B',
  'categories': <Object?>[],
  'description': 'Synthetic citation',
  'business_snapshot': saved,
};
void main() {
  setUpAll(() {
    final adapter = OrdinanceHiveModelAdapter();
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
  });
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  testWidgets(
    'changed business rejects submit, retains draft and requires a new review',
    (tester) async {
      final original = FlutterImageCompressPlatform.instance;
      FlutterImageCompressPlatform.instance = BoundaryImageCompressor();
      addTearDown(() => FlutterImageCompressPlatform.instance = original);
      final folder = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('snapshot-review-'),
      ))!;
      final photo = (await tester.runAsync(
        () => File('${folder.path}/synthetic.png').writeAsBytes(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a9ZkAAAAASUVORK5CYII=',
          ),
        ),
      ))!;
      addTearDown(() => folder.delete(recursive: true));
      var reviews = 0, submissions = 0;
      final bloc = (await tester.runAsync(
        () => listBloc((options) async {
          if (options.path.endsWith('/verify')) {
            reviews++;
            return reply(options, {
              'business_snapshot': {
                ...snapshot,
                'business_name': reviews == 1
                    ? 'Market Fish A'
                    : 'Market Fish B',
              },
              'reviewed_business_snapshot': 'server-business-$reviews',
              'reviewed_calculation': 'server-calculation',
              'calculation': {
                'total_payment_amount': 500,
                'highest_severity': 'Minor',
                'breakdown': [
                  {
                    'ordinance_id': 1,
                    'ordinance_no': '011',
                    'ordinance_code': 'SAN',
                    'offense_number': 1,
                    'payment_amount': 500,
                    'severity': 'Minor',
                    'is_duplicate': false,
                  },
                ],
              },
            });
          }
          if (options.path.endsWith('/new-inspection')) {
            submissions++;
            final form = options.data as FormData;
            expect(form.files.map((item) => item.key).toList(), [
              'supporting_evidence_files',
              'paper_ticket_photo',
            ]);
            expect(
              form.files.every(
                (item) => item.value.contentType?.mimeType == 'image/jpeg',
              ),
              isTrue,
            );
            expect(
              Map.fromEntries(form.fields)['reviewed_business_snapshot'],
              'server-business-1',
            );
            throw DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              response: Response<Object?>(
                requestOptions: options,
                statusCode: 409,
                data: {
                  'title': 'Conflict',
                  'message':
                      'Business details changed. Review and verify again before submitting.',
                },
              ),
            );
          }
          throw StateError('Unexpected snapshot test request: ${options.path}');
        }),
      ))!;
      addTearDown(bloc.close);
      final draft = InspectionFormData(
        personId: 31,
        personFullName: 'Synthetic Person',
        paperViolatorName: 'Synthetic Person',
        paperReference: 'SNAP-0001',
        issuePlace: 'Fish aisle',
        enforcerId: 3,
        vendorSummary: vendor,
        fineSummary: null,
        ordinances: [OrdinanceModel.fromJson(ordinanceResponse).toEntity()],
        evidences: [XFile(photo.path)],
        paperTicketPhoto: XFile(photo.path),
        description: 'Synthetic market citation',
        ticketType: ViolationType.ticket,
        penaltyType: PenaltyType.cashFine,
        communityServiceHrs: null,
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
      final submit = find.byWidgetPredicate(
        (w) => w is AppPrimaryButton && w.label == 'Submit Ticket',
      );
      await tester.ensureVisible(find.text('Verify ticket'));
      final verifiedState = bloc.stream.firstWhere(
        (state) => state is InspectionVerified,
      );
      await tester.tap(find.text('Verify ticket'));
      await tester.runAsync(
        () => verifiedState.timeout(const Duration(seconds: 5)),
      );
      await flush(tester);
      expect(find.text('Market Fish A'), findsOneWidget);
      expect(tester.widget<AppPrimaryButton>(submit).onPressed, isNotNull);
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await flush(tester);
      final confirm = find.byWidgetPredicate(
        (w) => w is AppPrimaryButton && w.label.startsWith('Issue ticket '),
      );
      await tester.ensureVisible(confirm);
      final rejectedState = bloc.stream.firstWhere(
        (state) => state is InspectionSubmitError,
      );
      await tester.tap(confirm);
      await tester.runAsync(
        () => rejectedState.timeout(const Duration(seconds: 5)),
      );
      await flush(tester);
      expect(submissions, 1);
      expect(tester.widget<AppPrimaryButton>(submit).onPressed, isNull);
      expect(
        tester
            .widget<NewInspectionPreviewPage>(
              find.byType(NewInspectionPreviewPage),
            )
            .formData,
        same(draft),
      );
      expect(draft.evidences!.single.path, photo.path);
      await tester.ensureVisible(find.text('Verify ticket'));
      final renewedState = bloc.stream.firstWhere(
        (state) => state is InspectionVerified,
      );
      await tester.tap(find.text('Verify ticket'));
      await tester.runAsync(
        () => renewedState.timeout(const Duration(seconds: 5)),
      );
      await flush(tester);
      expect(reviews, 2);
      expect(find.text('Market Fish B'), findsOneWidget);
      expect(find.text('Market Fish A'), findsNothing);
      expect(tester.widget<AppPrimaryButton>(submit).onPressed, isNotNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'saved citation uses historical values instead of changed registry',
    (tester) async {
      final ticket = TicketDetailModel.fromJson(record(snapshot)).toEntity();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ViolatorDetailSection(ticket: ticket, isTicket: true),
            ),
          ),
        ),
      );
      expect(find.text('Owner A'), findsOneWidget);
      expect(find.text('Market Fish A'), findsOneWidget);
      expect(find.text('SNAP-001'), findsOneWidget);
      expect(find.text('14 Market Lane'), findsOneWidget);
      expect(find.text('Current Owner B'), findsNothing);
    },
  );
  testWidgets('legacy citation does not manufacture historical business data', (
    tester,
  ) async {
    final ticket = TicketDetailModel.fromJson(record(null)).toEntity();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ViolatorDetailSection(ticket: ticket, isTicket: true),
          ),
        ),
      ),
    );
    expect(
      find.text('Historical business details unavailable.'),
      findsOneWidget,
    );
    expect(find.text('Business B'), findsNothing);
    expect(find.text('Current address B'), findsNothing);
  });
}
