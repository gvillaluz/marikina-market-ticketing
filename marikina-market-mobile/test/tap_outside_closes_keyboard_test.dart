import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_hive_model.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/community_service_progress.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/auth/presentation/widgets/change_password_card.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/widgets/reset_password_fields.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/fine_summary_model.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ticket_settlement_data.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/create_person_sheet.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/assessed_fine_field.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/paper_citation_fields.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/warning_violation_card.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/community_service_log_section.dart';
import 'package:pinput/pinput.dart';

import 'core/login_frame_test.dart' show withLogin;
import 'inspection_list_ui_test.dart' show listBloc;
import 'features/auth/login_screens_look_test.dart' show withMustChangeLogin;
import 'features/tickets/presentation/up_to_assessment_flow_test.dart'
    show calculation;

/// Taps into each text box, then on an empty corner of the screen, and
/// expects the keyboard to close (the box loses focus), box by box.
Future<void> expectTapOutsideCloses(WidgetTester tester, Finder boxes) async {
  final count = boxes.evaluate().length;
  expect(count, greaterThan(0));
  for (var i = 0; i < count; i++) {
    final box = boxes.at(i);
    final editable = find
        .descendant(of: box, matching: find.byType(EditableText))
        .first;
    bool focused() => tester.widget<EditableText>(editable).focusNode.hasFocus;
    await tester.ensureVisible(box);
    await tester.pump();
    await tester.tap(box);
    await tester.pump();
    expect(focused(), isTrue, reason: 'box $i takes the keyboard');
    await tester.tapAt(const Offset(1, 1));
    await tester.pump();
    expect(focused(), isFalse, reason: 'tapping outside box $i closes it');
  }
}

Widget page(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('log in boxes', (tester) async {
    await withLogin(tester, (router, bloc) async {
      await expectTapOutsideCloses(tester, find.byType(TextField));
    });
  });

  testWidgets('6-digit code boxes', (tester) async {
    await withMustChangeLogin(tester, (verify) async {
      await expectTapOutsideCloses(tester, find.byType(Pinput));
    });
  });

  testWidgets('change-password boxes', (tester) async {
    await withMustChangeLogin(tester, (verify) async {
      verify('001234');
      await tester.pumpAndSettle();
      expect(find.byType(ChangePasswordCard), findsOneWidget);
      await expectTapOutsideCloses(tester, find.byType(TextField));
    });
  });

  testWidgets('forgot password: new password boxes', (tester) async {
    final newPassword = TextEditingController();
    final confirm = TextEditingController();
    addTearDown(newPassword.dispose);
    addTearDown(confirm.dispose);
    await tester.pumpWidget(
      page(
        ResetPasswordFields(
          newPasswordController: newPassword,
          confirmNewPasswordController: confirm,
        ),
      ),
    );
    await expectTapOutsideCloses(tester, find.byType(TextField));
  });

  testWidgets('new inspection: paper ticket boxes', (tester) async {
    final reference = TextEditingController();
    final place = TextEditingController();
    addTearDown(reference.dispose);
    addTearDown(place.dispose);
    await tester.pumpWidget(
      page(
        PaperCitationFields(
          isTicket: true,
          referenceController: reference,
          placeController: place,
        ),
      ),
    );
    await expectTapOutsideCloses(tester, find.byType(TextField));
  });

  testWidgets('new inspection: warning boxes', (tester) async {
    final place = TextEditingController();
    final description = TextEditingController();
    addTearDown(place.dispose);
    addTearDown(description.dispose);
    await tester.pumpWidget(
      page(
        WarningViolationCard(
          placeOfApprehensionController: place,
          descriptionController: description,
          onPressed: (_) {},
        ),
      ),
    );
    await expectTapOutsideCloses(tester, find.byType(TextField));
  });

  testWidgets('new inspection: create person boxes', (tester) async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(OrdinanceHiveModelAdapter());
    }
    final bloc = await tester.runAsync(
      () => listBloc((options) async => throw StateError('No request')),
    );
    await tester.pumpWidget(
      BlocProvider<InspectionBloc>.value(
        value: bloc!,
        child: page(const CreatePersonSheet(name: '')),
      ),
    );
    await expectTapOutsideCloses(tester, find.byType(TextField));
  });

  testWidgets('new inspection: fine box', (tester) async {
    final item = FineSummaryModel.fromJson(
      calculation(),
    ).toEntity().breakdownItems.single;
    await tester.pumpWidget(
      page(AssessedFineField(item: item, value: '600', onChanged: (_) {})),
    );
    await expectTapOutsideCloses(tester, find.byType(TextField));
  });

  testWidgets('ticket: community service hours box', (tester) async {
    await tester.pumpWidget(
      page(
        CommunityServiceLogSection(
          settlement: const TicketSettlementData(
            ticketId: 2,
            penaltyType: PenaltyType.communityService,
            ticketStatus: TicketStatus.inProgress,
            requiredHours: 8,
            communityServiceProgress: CommunityServiceProgress(
              ticketId: 2,
              hoursRequired: 8,
              hoursCompleted: 2,
              hoursRemaining: 6,
              completionPercentage: 25,
              entries: [],
            ),
            isReceiptSubmitted: false,
            isLoading: false,
            isLoaded: true,
            isSubmitting: false,
          ),
          onRetryLoad: () {},
          onSubmit: (_) {},
        ),
      ),
    );
    await tester.tap(find.text('Add Service Entry'));
    await tester.pumpAndSettle();
    await expectTapOutsideCloses(tester, find.byType(TextField));
  });
}
