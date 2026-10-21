import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/severity.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/fine_summary.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_event.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_state.dart';
import 'inspection_list_ui_test.dart' show listBloc;
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/preview/penalty_details_section.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/preview/violation_details_section.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/detail_row.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/inspection_type_toggle.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/preview/photo_evidence_preview_section.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/preview/submit_confirmation_bottom_sheet.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/preview/process_loading_overlay.dart';

Future<void> showCreationWidget(
  WidgetTester tester,
  Widget widget, {
  double scale = 2,
}) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light,
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: Scaffold(body: widget),
      ),
    ),
  ),
);

void main() {
  testWidgets('preview detail sections wrap at 280px with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(280, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await showCreationWidget(
      tester,
      const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            DetailRow(
              label: 'COMMUNITY SERVICE HOURS:',
              value: 'Three hours of community service',
            ),
            PenaltyDetailsSection(
              severity: Severity.moderate,
              penaltyType: PenaltyType.cashFine,
              totalFineAmount: 1500,
              communityHrs: null,
            ),
            ViolationDetailsSection(
              ordinances: [],
              isTicket: false,
              marketSection: 'Section A',
              description: 'Keep the stall and its surroundings clean.',
            ),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test('duplicate submission makes only one request while pending', () async {
    final started = Completer<RequestOptions>();
    final pending = Completer<Response<Object?>>();
    var calls = 0;
    final bloc = await listBloc((options) {
      calls++;
      started.complete(options);
      return pending.future;
    });
    NewInspectionSubmitted submission() => NewInspectionSubmitted(
      vendorId: 12,
      enforcerId: 7,
      marketSectionId: 1,
      ticketType: ViolationType.warning,
      ordinanceIds: [1],
      penaltyType: PenaltyType.cashFine,
      communityServiceHours: null,
      description: 'Keep the stall and its surroundings clean.',
      primaryCategory: [],
      evidences: null,
    );
    bloc.add(submission());
    final options = await started.future;
    bloc.add(submission());
    await Future<void>.delayed(Duration.zero);
    expect(calls, 1);
    final failed = bloc.stream.firstWhere(
      (state) => state is InspectionSubmitConnectionError,
    );
    pending.completeError(
      DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      ),
    );
    await failed;
  });
  testWidgets(
    'photo preview uses valid parent data and bounds thumbnail decoding',
    (tester) async {
      final folder = await tester.runAsync(
        () => Directory.systemTemp.createTemp('inspection-photo-test-'),
      );
      final file = File('${folder!.path}/photo.png');
      await tester.runAsync(
        () => file.writeAsBytes(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/G0sAAAAASUVORK5CYII=',
          ),
        ),
      );
      addTearDown(() => folder.delete(recursive: true));
      await showCreationWidget(
        tester,
        PhotoEvidencePreviewSection(evidences: [XFile(file.path)]),
        scale: 1,
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        tester.widget<Image>(find.byType(Image).first).image,
        isA<ResizeImage>(),
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'inspection type controls wrap large text at 280px and disabled controls do not fire',
    (tester) async {
      tester.view.physicalSize = const Size(280, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var changes = 0;
      await showCreationWidget(
        tester,
        Padding(
          padding: AppTheme.inspectionCardPadding,
          child: InspectionTypeToggle(
            selected: ViolationType.ticket,
            onChange: (_) => changes++,
            isEnabled: false,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Warning'));
      expect(changes, 0);
    },
  );

  testWidgets('ticket confirmation scrolls with a keyboard and submits once', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(280, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    var submits = 0;
    await showCreationWidget(
      tester,
      SubmitConfirmationBottomSheet(
        isTicket: true,
        penaltyType: PenaltyType.cashFine,
        severity: Severity.moderate,
        fineSummary: FineSummary(
          totalPaymentAmount: 1500,
          severity: Severity.moderate,
          breakdownItems: [],
        ),
        onPressed: () => submits++,
      ),
    );
    expect(tester.takeException(), isNull);
    final button = find.byType(ElevatedButton).first;
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    await tester.tap(button);
    expect(submits, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'processing dialog supports reduced motion without scheduled animation',
    (tester) async {
      await showCreationWidget(
        tester,
        const ProcessLoadingOverlay(message: 'Recording your inspection.'),
      );
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
