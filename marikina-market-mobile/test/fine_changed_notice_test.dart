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
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_hive_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_model.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/fine_summary.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/inspection_form_data.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_state.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/pages/new_inspection_preview_page.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/preview/fine_changed_notice.dart';

import 'features/auth/data/login_mobile_contract_test.dart' show reply;
import 'features/tickets/data/models/ordinance_model_test.dart'
    show ordinanceResponse;
import 'features/tickets/presentation/business_snapshot_test.dart'
    show snapshot;
import 'fine_summary_display_test.dart' show line, summaryOf;
import 'inspection_list_ui_test.dart' show listBloc;
import 'inspection_preview_navigation_test.dart' show vendor, flush;

// Criterion 4: the fine on the entry page is provisional. The enforcer copies
// it onto the paper, then Verify works it out again on the server. If the
// server's answer differs, the Review page must say what to write instead.
// Expected wording is fixed by hand below; no real server or database is used.

const changedFine =
    'The fine changed after you copied it. Write ₱1,000.00 on the paper '
    'ticket instead of ₱500.00.';

final firstOffense = summaryOf([line(12, '12', 1, amount: 500)], total: 500);
final firstOffenseAgain = summaryOf([
  line(12, '12', 1, amount: 500),
], total: 500);
final secondOffenseAt1000 = summaryOf([
  line(12, '12', 2, amount: 1000),
], total: 1000);
final secondOffenseAt500 = summaryOf([
  line(12, '12', 2, amount: 500),
], total: 500);

Future<void> pumpNotice(
  WidgetTester tester, {
  required FineSummary? copiedSummary,
  required FineSummary? verifiedSummary,
  PenaltyType? penaltyType = PenaltyType.cashFine,
}) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: FineChangedNotice(
        copied: copiedSummary,
        verified: verifiedSummary,
        penaltyType: penaltyType,
      ),
    ),
  ),
);

void main() {
  group('the notice', () {
    testWidgets('says nothing when the fine and positions are unchanged', (
      tester,
    ) async {
      await pumpNotice(
        tester,
        copiedSummary: firstOffense,
        verifiedSummary: firstOffenseAgain,
      );
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('says what to write instead when the fine changed', (
      tester,
    ) async {
      await pumpNotice(
        tester,
        copiedSummary: firstOffense,
        verifiedSummary: secondOffenseAt1000,
      );
      expect(find.text(changedFine), findsOneWidget);
    });

    testWidgets('names a changed offense position even when the fine is the '
        'same', (tester) async {
      await pumpNotice(
        tester,
        copiedSummary: firstOffense,
        verifiedSummary: secondOffenseAt500,
      );
      expect(
        find.text('Section 12 is now the 2nd offense, not the 1st.'),
        findsOneWidget,
      );
      expect(find.textContaining('Write'), findsNothing);
    });

    testWidgets('does not mention a fine for blood donation, which has none '
        'on the paper', (tester) async {
      await pumpNotice(
        tester,
        copiedSummary: firstOffense,
        verifiedSummary: secondOffenseAt1000,
        penaltyType: PenaltyType.bloodDonation,
      );
      expect(find.textContaining('Write'), findsNothing);
      expect(
        find.text('Section 12 is now the 2nd offense, not the 1st.'),
        findsOneWidget,
      );
    });

    testWidgets('says nothing before Verify has answered', (tester) async {
      await pumpNotice(
        tester,
        copiedSummary: firstOffense,
        verifiedSummary: null,
      );
      expect(find.byType(Text), findsNothing);
    });
  });

  group('the Review page', () {
    setUpAll(() {
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(OrdinanceHiveModelAdapter());
      }
    });
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    Future<(InspectionBloc, InspectionFormData)> setUpPage(
      WidgetTester tester,
      Map<String, Object?> answer,
    ) async {
      final folder = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('fine-changed-'),
      ))!;
      final photo = (await tester.runAsync(
        () => File('${folder.path}/paper.png').writeAsBytes(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a9ZkAAAAASUVORK5CYII=',
          ),
        ),
      ))!;
      addTearDown(() => folder.delete(recursive: true));
      final bloc = (await tester.runAsync(
        () => listBloc((options) async {
          expect(options.path, '/enforcer/tickets/verify');
          return reply(options, {
            'reviewed_calculation': 'opaque',
            'reviewed_business_snapshot': 'opaque-business',
            'business_snapshot': snapshot,
            'calculation': answer,
          });
        }),
      ))!;
      addTearDown(bloc.close);
      final draft = InspectionFormData(
        vendorSummary: vendor,
        enforcerId: 7,
        personId: 31,
        paperViolatorName: 'Synthetic Vendor',
        paperReference: 'S4-0001',
        issuePlace: 'Market aisle',
        description: 'Copied from the system',
        ticketType: ViolationType.ticket,
        penaltyType: PenaltyType.cashFine,
        communityServiceHrs: null,
        fineSummary: firstOffense,
        ordinances: [
          OrdinanceModel.fromJson({
            ...ordinanceResponse,
            'id': 12,
            'section': '12',
            'severity': 'Minor',
          }).toEntity(),
        ],
        paperTicketPhoto: XFile(photo.path),
        evidences: [XFile(photo.path)],
      );
      return (bloc, draft);
    }

    Future<void> verify(WidgetTester tester, InspectionBloc bloc) async {
      final button = find.byWidgetPredicate(
        (w) => w is AppPrimaryButton && w.label == 'Verify ticket',
      );
      await tester.ensureVisible(button);
      final checked = bloc.stream.firstWhere(
        (state) => state is InspectionVerified,
      );
      await tester.tap(button);
      await tester.runAsync(() => checked.timeout(const Duration(seconds: 5)));
      await flush(tester);
    }

    Future<void> openPage(
      WidgetTester tester,
      InspectionBloc bloc,
      InspectionFormData draft,
    ) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<InspectionBloc>.value(
            value: bloc,
            child: NewInspectionPreviewPage(formData: draft),
          ),
        ),
      );
      await flush(tester);
    }

    Finder submit() => find.byWidgetPredicate(
      (w) => w is AppPrimaryButton && w.label == 'Submit Ticket',
    );

    testWidgets('warns after Verify when the server fine differs, and still '
        'lets the enforcer submit', (tester) async {
      final (bloc, draft) = await setUpPage(tester, secondOffenseAt1000Json);
      await openPage(tester, bloc, draft);
      expect(find.text(changedFine), findsNothing, reason: 'before Verify');
      await verify(tester, bloc);
      expect(find.text(changedFine), findsOneWidget);
      expect(tester.widget<AppPrimaryButton>(submit()).onPressed, isNotNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('shows no warning when the server agrees with the copy', (
      tester,
    ) async {
      final (bloc, draft) = await setUpPage(tester, firstOffenseJson);
      await openPage(tester, bloc, draft);
      await verify(tester, bloc);
      expect(find.textContaining('changed after you copied'), findsNothing);
      expect(tester.widget<AppPrimaryButton>(submit()).onPressed, isNotNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}

const firstOffenseJson = <String, Object?>{
  'total_payment_amount': 500,
  'highest_severity': 'Minor',
  'breakdown': [
    {
      'ordinance_id': 12,
      'ordinance_no': '011',
      'section': '12',
      'payment_amount': 500,
      'severity': 'Minor',
      'offense_number': 1,
      'is_duplicate': false,
      'fine_kind': 'Fixed',
    },
  ],
};

const secondOffenseAt1000Json = <String, Object?>{
  'total_payment_amount': 1000,
  'highest_severity': 'Minor',
  'breakdown': [
    {
      'ordinance_id': 12,
      'ordinance_no': '011',
      'section': '12',
      'payment_amount': 1000,
      'severity': 'Minor',
      'offense_number': 2,
      'is_duplicate': false,
      'fine_kind': 'Fixed',
    },
  ],
};
