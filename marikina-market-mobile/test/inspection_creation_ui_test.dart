import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

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
  bool disableAnimations = true,
}) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light,
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: disableAnimations,
        ),
        child: Scaffold(body: widget),
      ),
    ),
  ),
);

void main() {
  for (final penalty in PenaltyType.values) {
    testWidgets('preview total is cash-only for ${penalty.name}', (
      tester,
    ) async {
      await showCreationWidget(
        tester,
        SingleChildScrollView(
          child: PenaltyDetailsSection(
            severity: Severity.moderate,
            penaltyType: penalty,
            totalFineAmount: 12500.50,
            communityHrs: 3,
          ),
        ),
        scale: 1,
      );
      if (penalty == PenaltyType.cashFine) {
        expect(find.text('₱12,500.50'), findsOneWidget);
        final panel = find
            .ancestor(
              of: find.text('Total Fine Due:'),
              matching: find.byType(Container),
            )
            .first;
        expect(
          tester.getSize(panel).width,
          tester.getSize(find.byType(Scaffold)).width,
        );
      } else {
        expect(find.text('Total Fine Due:'), findsNothing);
        expect(find.textContaining('Please settle the fine'), findsNothing);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('wide detail rows align values to the right', (tester) async {
    await showCreationWidget(
      tester,
      const DetailRow(label: 'TRADE NAME:', value: 'Marikina Fresh Produce'),
      scale: 1,
    );
    final value = tester.widget<Text>(find.text('Marikina Fresh Produce'));
    expect(value.textAlign, TextAlign.right);
  });

  testWidgets('detail rows keep space between with enlarged text', (
    tester,
  ) async {
    await showCreationWidget(
      tester,
      const SizedBox(
        width: 280,
        child: DetailRow(
          label: 'ADDRESS:',
          value: 'Marikina Public Market, Section A',
        ),
      ),
    );
    final label = tester.getRect(find.text('ADDRESS:'));
    final value = tester.getRect(
      find.text('Marikina Public Market, Section A'),
    );
    expect(value.top, label.top);
    expect(value.left, greaterThan(label.right));
    expect(value.right, tester.getRect(find.byType(DetailRow)).right);
    expect(tester.takeException(), isNull);
  });

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
    final release = Completer<void>();
    var calls = 0;
    final bloc = await listBloc((options) async {
      calls++;
      if (!started.isCompleted) started.complete(options);
      await release.future;
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
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
    try {
      bloc.add(submission());
      final options = await started.future;
      expect(options.method, 'POST');
      expect(options.path, '/enforcer/tickets/new-inspection');
      expect(bloc.state, isA<SubmitNewTicketLoading>());
      bloc.add(submission());
      await pumpEventQueue();
      expect(calls, 1);
      expect(bloc.state, isA<SubmitNewTicketLoading>());
      final failed = bloc.stream.firstWhere(
        (state) => state is InspectionSubmitConnectionError,
      );
      release.complete();
      await failed;
      expect(calls, 1);
    } finally {
      if (!release.isCompleted) release.complete();
    }
  });
  testWidgets(
    'photo preview uses valid parent data and bounds thumbnail decoding',
    (tester) async {
      final folder = await tester.runAsync(
        () => Directory.systemTemp.createTemp('inspection-photo-test-'),
      );
      final file = File('${folder!.path}/photo.png');
      await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        Canvas(recorder).drawColor(Colors.black, BlendMode.src);
        final picture = recorder.endRecording();
        final image = await picture.toImage(4, 4);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
        picture.dispose();
      });
      addTearDown(() => folder.delete(recursive: true));
      await tester.runAsync(() async {
        await showCreationWidget(
          tester,
          PhotoEvidencePreviewSection(evidences: [XFile(file.path)]),
          scale: 1,
        );
        final provider = tester.widget<Image>(find.byType(Image).first).image;
        await precacheImage(
          provider,
          tester.element(find.byType(Image).first),
        ).timeout(const Duration(seconds: 5));
      });
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        tester.widget<Image>(find.byType(Image).first).image,
        isA<ResizeImage>(),
      );
      expect(
        tester.widget<RawImage>(find.byType(RawImage).first).image,
        isNotNull,
      );
      final provider = tester.widget<Image>(find.byType(Image).first).image;
      expect(
        (provider as ResizeImage).width,
        inInclusiveRange(1, AppTheme.evidenceDecodeMaxWidth),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() => provider.evict());
      await tester.pumpAndSettle();
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

  for (final disableAnimations in [true, false]) {
    testWidgets(
      'processing dialog exposes valid semantics: disableAnimations=$disableAnimations',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          await showCreationWidget(
            tester,
            const ProcessLoadingOverlay(message: 'Recording your inspection.'),
            disableAnimations: disableAnimations,
          );
          if (disableAnimations) {
            await tester.pumpAndSettle();
            expect(tester.binding.hasScheduledFrame, isFalse);
          } else {
            await tester.pump(const Duration(milliseconds: 100));
            expect(tester.binding.hasScheduledFrame, isTrue);
          }
          final indicator = find.byType(CircularProgressIndicator);
          expect(indicator, findsOneWidget);
          final data = tester.getSemantics(indicator).getSemanticsData();
          expect(data.label, 'Processing inspection');
          expect(data.value, disableAnimations ? '75' : '');
          expect(data.minValue, disableAnimations ? '0' : isNull);
          expect(data.maxValue, disableAnimations ? '100' : isNull);
          expect(find.text('Recording your inspection.'), findsOneWidget);
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          semantics.dispose();
        }
      },
    );
  }
}
