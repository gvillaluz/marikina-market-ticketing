import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/severity.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/business_snapshot.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ordinance.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ticket_detail.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ticket_detail_content_data.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/vendor_summary.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/violation_summary.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/ordinance_category.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/business_type.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/copy_to_paper_card.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/preview/penalty_details_section.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/preview/violation_details_section.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/preview/violator_info_section.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/ticket_detail_content.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/ticket_violation_section.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/violator_detail_section.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/ticket_paper_header.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/ticket_paper_field.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/ticket_paper_field_group.dart';

const capturePreviews = bool.fromEnvironment('SLICE3A_PREVIEWS');

Future<void> capturePaper(WidgetTester tester, String name) async {
  if (!capturePreviews) return;
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('paper-preview')),
    );
    final image = await boundary.toImage();
    try {
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        '../evidence/enforcer-ticket-paper-slice-3a/redesign-$name.png',
      ).writeAsBytes(png!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

TicketDetail ticketDetail({
  required bool isTicket,
  required String control,
  String paperNumber = '000456',
  PenaltyType penalty = PenaltyType.cashFine,
  BusinessSnapshot? snapshot,
  int? vendorId = 12,
}) {
  return TicketDetail(
    businessSnapshot: snapshot,
    ticketId: 42,
    paperReference: isTicket ? paperNumber : null,
    issuePlace: isTicket ? 'Fish aisle near F-014' : null,
    controlNumber: control,
    enforcerId: 7,
    vendorId: vendorId,
    violationType: isTicket ? ViolationType.ticket : ViolationType.warning,
    businessType: BusinessType.public,
    businessAccountNumber: 'TEST-12',
    stallNumber: 'A-12',
    tradeName: 'Synthetic Market Goods',
    lastName: 'Vendor',
    firstName: 'Synthetic',
    address: 'Synthetic Street, Marikina',
    violations: [
      ViolationSummary(
        ordinanceId: 11,
        ordinanceNo: '2026-123456789',
        series: '2026',
        section: '8',
        paymentAmount: 1500,
        offenseNumber: 1,
      ),
    ],
    issuedAt: DateTime.utc(2026, 10, 7, 8),
    marketSectionName: 'Section A',
    categories: [OrdinanceCategory.sanitation],
    description: 'Obstructed aisle',
    severity: Severity.minor,
    penaltyType: penalty,
    dueDate: DateTime.utc(2026, 10, 12),
    totalFineAmount: 1500,
    evidenceUrls: [],
  );
}

TicketDetailContent paper({
  required bool isTicket,
  required String control,
  String paperNumber = '000456',
  PenaltyType penalty = PenaltyType.cashFine,
}) {
  return TicketDetailContent(
    data: TicketDetailContentData(
      ticket: ticketDetail(
        isTicket: isTicket,
        control: control,
        paperNumber: paperNumber,
        penalty: penalty,
      ),
      droppedOrdinances: null,
      settlement: null,
    ),
    onRetrySettlementLoad: () {},
    onSubmitReceipt: (_) {},
    onSubmitCommunityServiceLog: (_) {},
  );
}

Future<void> showPaper(WidgetTester tester, double width, Widget child) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: capturePreviews
          ? AppTheme.light.copyWith(
              textTheme: AppTheme.light.textTheme.apply(fontFamily: 'Roboto'),
            )
          : AppTheme.light,
      home: RepaintBoundary(
        key: const ValueKey('paper-preview'),
        child: Scaffold(
          backgroundColor: AppTheme.ticketDetailBackground,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    ),
  );
  if (capturePreviews) {
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/logo/org_logo.png'),
        tester.element(find.byType(Scaffold)),
      ),
    );
  }
  await tester.pump();
}

void main() {
  testWidgets(
    'cash ordinance price sits at the right of its card, level with the badge',
    (tester) async {
      await showPaper(
        tester,
        400,
        paper(isTicket: true, control: 'TKT-2026-0042'),
      );
      final price = find.descendant(
        of: find.byType(TicketViolationSection),
        matching: find.text('₱1,500.00'),
      );
      final card = find
          .ancestor(
            of: price,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Container &&
                  widget.decoration is BoxDecoration &&
                  (widget.decoration! as BoxDecoration).borderRadius ==
                      BorderRadius.circular(10),
            ),
          )
          .first;
      expect(
        tester.getBottomRight(price).dx,
        closeTo(tester.getBottomRight(card).dx - 13, 1),
      );
      expect(
        tester.getCenter(price).dy,
        closeTo(tester.getCenter(find.text('1st offense')).dy, 1),
      );
      expect(tester.takeException(), isNull);
    },
  );
  for (final penalty in [
    PenaltyType.bloodDonation,
    PenaltyType.communityService,
  ]) {
    testWidgets('non-cash ordinance hides price for ${penalty.name}', (
      tester,
    ) async {
      await showPaper(
        tester,
        400,
        paper(isTicket: true, control: 'TKT-2026-0042', penalty: penalty),
      );
      expect(find.text('1st offense'), findsOneWidget);
      expect(find.text('₱1,500.00'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  for (final width in [280.0, 400.0]) {
    testWidgets(
      'preview and issued headers fit at ${width}px with enlarged text',
      (tester) async {
        // Control number = the paper ticket's printed number; old tickets have none.
        for (final paperNumber in <String?>[
          null,
          '000456-2026-00000000000000000042',
        ]) {
          await showPaper(
            tester,
            width,
            MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
              child: TicketPaperHeader(
                isTicket: true,
                paperReference: paperNumber,
              ),
            ),
          );
          final shown = paperNumber == null
              ? 'Unavailable (legacy record)'
              : '#$paperNumber';
          expect(find.text('CONTROL NUMBER:'), findsOneWidget);
          expect(find.text(shown), findsOneWidget);
          final title = tester.getRect(find.text('VIOLATION TICKET'));
          final number = tester.getRect(find.text(shown));
          expect(title.right, lessThanOrEqualTo(number.left));
          expect(title.top, lessThan(number.bottom));
          expect(number.top, lessThan(title.bottom));
          expect(tester.takeException(), isNull);
        }
      },
    );
    testWidgets(
      'paper fields preserve long values at ${width}px with enlarged text',
      (tester) async {
        const address = 'Unit 12, Synthetic Market Building, Marikina City';
        await showPaper(
          tester,
          width,
          const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(2)),
            child: TicketPaperFieldGroup(
              spacing: AppTheme.inspectionSmallGap,
              fields: [TicketPaperField(label: 'ADDRESS:', value: address)],
            ),
          ),
        );
        expect(find.text(address), findsOneWidget);
        expect(
          tester.getTopLeft(find.text(address)).dy,
          greaterThan(tester.getBottomLeft(find.text('ADDRESS:')).dy),
        );
        expect(
          tester.widget<Text>(find.text(address)).overflow,
          isNot(TextOverflow.ellipsis),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  setUpAll(() async {
    if (!capturePreviews) return;
    final sdkRoot = Platform.environment['FLUTTER_ROOT']!;
    final fonts = FontLoader('Roboto');
    for (final file in ['roboto-regular.ttf', 'roboto-bold.ttf']) {
      fonts.addFont(
        File(
          '$sdkRoot/bin/cache/artifacts/material_fonts/$file',
        ).readAsBytes().then(ByteData.sublistView),
      );
    }
    await fonts.load();
    await (FontLoader('MaterialIcons')..addFont(
          File(
            '$sdkRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
          ).readAsBytes().then(ByteData.sublistView),
        ))
        .load();
  });
  for (final isTicket in [true, false]) {
    testWidgets('paper has a defined document surface for ticket=$isTicket', (
      tester,
    ) async {
      await showPaper(
        tester,
        400,
        paper(isTicket: isTicket, control: 'TKT-2026-0042'),
      );
      final surfaces = tester
          .widgetList<Container>(
            find.ancestor(
              of: find.text('City of Marikina'),
              matching: find.byType(Container),
            ),
          )
          .where((container) => container.decoration is BoxDecoration);
      final decoration = surfaces.first.decoration! as BoxDecoration;
      expect(decoration.border, isNotNull);
      expect(decoration.color, Colors.white);
      expect(tester.takeException(), isNull);
    });
    testWidgets('paper header aligns logo and title for ticket=$isTicket', (
      tester,
    ) async {
      await showPaper(
        tester,
        480,
        paper(isTicket: isTicket, control: 'TKT-2026-0042'),
      );
      final title = find.text(
        isTicket ? 'VIOLATION TICKET' : 'WRITTEN WARNING',
      );
      expect(find.text('City of Marikina'), findsOneWidget);
      expect(find.text('Marikina Public Market Office'), findsOneWidget);
      expect(
        tester.getCenter(title).dy,
        closeTo(tester.getCenter(find.byType(Image).first).dy, 1),
      );
      // The app's own number (TKT-2026-0042) is never shown on a ticket.
      expect(find.text('SYSTEM CONTROL:'), findsNothing);
      expect(find.text('PAPER REFERENCE:'), findsNothing);
      expect(find.textContaining('WARNING REFERENCE'), findsNothing);
      if (isTicket) {
        expect(find.text('CONTROL NUMBER:'), findsOneWidget);
        expect(find.text('#000456'), findsOneWidget);
        expect(find.textContaining('TKT-2026-0042'), findsNothing);
        expect(find.text('Fish aisle near F-014'), findsOneWidget);
        expect(find.text('PENDING'), findsNothing);
        // 20px page padding + 20px paper padding puts the right edge at 440.
        expect(tester.getTopRight(find.text('#000456')).dx, closeTo(440, 1));
      } else {
        // A warning has no printed number; its own number is its control number.
        expect(find.text('CONTROL NUMBER:'), findsNothing);
        expect(
          find.textContaining('CONTROL NUMBER: #TKT-2026-0042'),
          findsOneWidget,
        );
      }
      expect(tester.takeException(), isNull);
      await capturePaper(
        tester,
        'paper-${isTicket ? 'ticket' : 'warning'}-480',
      );
    });
  }

  for (final width in [280.0, 400.0]) {
    testWidgets('long control number remains complete at ${width}px', (
      tester,
    ) async {
      // A long number printed on the paper ticket; the app's own number is not shown.
      const control = '000456-2026-00000000000000000042';
      await showPaper(
        tester,
        width,
        paper(isTicket: true, control: 'TKT-2026-0042', paperNumber: control),
      );
      expect(find.text('#$control'), findsOneWidget);
      final number = tester.widget<Text>(find.text('#$control'));
      expect(number.maxLines, isNull);
      expect(number.overflow, isNot(TextOverflow.ellipsis));
      final title = tester.getRect(find.text('VIOLATION TICKET'));
      final controlRect = tester.getRect(find.text('#$control'));
      expect(title.left, lessThan(controlRect.left));
      expect(title.top, lessThan(controlRect.bottom));
      expect(controlRect.top, lessThan(title.bottom));
      expect(
        tester.getTopRight(find.text('#$control')).dx,
        closeTo(width - 40, 1),
      );
      expect(tester.takeException(), isNull);
      await capturePaper(tester, 'paper-long-control-${width.toInt()}');
    });
  }

  testWidgets('warning header stays aligned at 280px with enlarged text', (
    tester,
  ) async {
    await showPaper(
      tester,
      280,
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: paper(isTicket: false, control: 'unused'),
      ),
    );
    expect(find.text('WRITTEN WARNING'), findsOneWidget);
    expect(find.text('SYSTEM CONTROL:'), findsNothing);
    expect(
      tester.getCenter(find.text('WRITTEN WARNING')).dy,
      closeTo(tester.getCenter(find.byType(Image).first).dy, 1),
    );
    expect(tester.takeException(), isNull);
    await capturePaper(tester, 'paper-warning-280-enlarged');
  });

  group('paper field label', () {
    const longValue = 'Synthetic Vendor Dela Cruz Santos Reyes Bautista';
    // The paper label is 12px and inherits the 1.45 body line height:
    // 12 * 1.45 = 17.4 per line (checked within 1px for line rounding).
    const oneLabelLine = 17.4;

    Future<void> showField(
      WidgetTester tester,
      double width,
      String label,
    ) async {
      tester.view.physicalSize = Size(width, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: TicketPaperFieldGroup(
                spacing: AppTheme.inspectionSmallGap,
                fields: [TicketPaperField(label: label, value: longValue)],
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('stays on one line beside a long value at 390px', (
      tester,
    ) async {
      await showField(tester, 390, 'REGISTERED OWNER:');
      final label = tester.getRect(find.text('REGISTERED OWNER:'));
      final value = tester.getRect(find.text(longValue));
      expect(label.height, closeTo(oneLabelLine, 1));
      expect(value.top, label.top);
      expect(value.left, label.right + AppTheme.ticketSmallGap);
      expect(value.right, 390);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sits above the value below the 280px breakpoint', (
      tester,
    ) async {
      await showField(tester, 279, 'NAME:');
      final label = tester.getRect(find.text('NAME:'));
      final value = tester.getRect(find.text(longValue));
      expect(value.top, greaterThan(label.bottom));
      expect(value.left, label.left);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a label too wide for the row sits above the value', (
      tester,
    ) async {
      const officer = 'NAME & SIGNATURE OF APPREHENDING OFFICER:';
      await showField(tester, 390, officer);
      final label = tester.getRect(find.text(officer));
      final value = tester.getRect(find.text(longValue));
      expect(value.top, greaterThan(label.bottom));
      expect(tester.takeException(), isNull);
    });

    for (final width in [280.0, 300.0, 320.0, 350.0, 390.0]) {
      testWidgets('real labels never overflow or wrap beside values at '
          '${width}px', (tester) async {
        for (final text in [
          'VIOLATION COMMITTED:',
          'BUSINESS ADDRESS:',
          'REGISTERED OWNER:',
          'RECORDED VIOLATOR:',
          'CONFIRMED PERSON:',
          'NAME & SIGNATURE OF APPREHENDING OFFICER:',
        ]) {
          await showField(tester, width, text);
          expect(tester.takeException(), isNull, reason: text);
          final label = tester.getRect(find.text(text));
          final value = tester.getRect(find.text(longValue));
          if (value.top == label.top) {
            expect(label.height, closeTo(oneLabelLine, 1), reason: text);
            expect(value.left, greaterThan(label.right), reason: text);
          } else {
            expect(value.top, greaterThan(label.bottom), reason: text);
          }
        }
      });
    }
  });

  for (final width in [280.0, 400.0]) {
    testWidgets('preview ordinance label has a 6px code gap at ${width}px', (
      tester,
    ) async {
      final ordinance = Ordinance(
        id: 11,
        ordinanceNo: '2026-123456789',
        series: '2026',
        section: '8',
        title: 'Keep market aisles clear',
        description: 'Obstruction',
        category: OrdinanceCategory.sanitation,
        severity: Severity.minor,
        createdAt: DateTime.utc(2026, 10, 7),
        updatedAt: DateTime.utc(2026, 10, 7),
        isActive: true,
        penaltyTierCount: 2,
      );
      await showPaper(
        tester,
        width,
        ViolationDetailsSection(
          ordinances: [ordinance],
          isTicket: false,
          marketSection: 'Section A',
          description: 'Obstructed aisle',
        ),
      );
      final label = find.text('Ord No. 2026-123456789, Series of 2026');
      expect(label, findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Section 8')).dy -
            tester.getBottomLeft(label).dy,
        6,
      );
      expect(tester.takeException(), isNull);
      await capturePaper(tester, 'preview-ordinance-${width.toInt()}');
    });
  }

  group('paper field group', () {
    // The paper label is 12px and inherits the 1.45 body line height:
    // 12 * 1.45 = 17.4 per line (checked within 1px for line rounding).
    const oneLabelLine = 17.4;

    Future<void> showGroup(
      WidgetTester tester,
      double width,
      List<TicketPaperField> fields,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: TicketPaperFieldGroup(
                spacing: AppTheme.inspectionSmallGap,
                fields: fields,
              ),
            ),
          ),
        ),
      );
    }

    final nameFields = [
      const TicketPaperField(label: 'NAME:', value: 'Juan Dela Cruz'),
      const TicketPaperField(label: 'REGISTERED OWNER:', value: 'Maria Santos'),
      const TicketPaperField(label: 'STALL/UNIT NO:', value: 'A-12'),
    ];

    testWidgets('values start at one left edge and labels stay on one line', (
      tester,
    ) async {
      await showGroup(tester, 390, nameFields);
      // REGISTERED OWNER: is the longest label. Every value starts one 12px
      // gap after its right edge, whatever each row's own label is.
      final column =
          tester.getRect(find.text('REGISTERED OWNER:')).right +
          AppTheme.ticketSmallGap;
      for (final field in nameFields) {
        final label = tester.getRect(find.text(field.label));
        final value = tester.getRect(find.text(field.value));
        expect(label.height, closeTo(oneLabelLine, 1), reason: field.label);
        expect(value.top, label.top, reason: field.label);
        expect(value.left, closeTo(column, 0.5), reason: field.label);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('one label too wide stacks every row of the group', (
      tester,
    ) async {
      await showGroup(tester, 390, const [
        TicketPaperField(label: 'NAME:', value: 'Juan Dela Cruz'),
        TicketPaperField(
          label: 'NAME & SIGNATURE OF APPREHENDING OFFICER:',
          value: 'Pedro Reyes',
        ),
      ]);
      for (final pair in [
        ('NAME:', 'Juan Dela Cruz'),
        ('NAME & SIGNATURE OF APPREHENDING OFFICER:', 'Pedro Reyes'),
      ]) {
        final label = tester.getRect(find.text(pair.$1));
        final value = tester.getRect(find.text(pair.$2));
        expect(value.top, greaterThan(label.bottom), reason: pair.$1);
        expect(value.left, label.left, reason: pair.$1);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('a group narrower than 280px stacks', (tester) async {
      await showGroup(tester, 279, const [
        TicketPaperField(label: 'NAME:', value: 'Juan Dela Cruz'),
        TicketPaperField(label: 'ADDRESS:', value: 'Synthetic Street'),
      ]);
      for (final pair in [
        ('NAME:', 'Juan Dela Cruz'),
        ('ADDRESS:', 'Synthetic Street'),
      ]) {
        expect(
          tester.getRect(find.text(pair.$2)).top,
          greaterThan(tester.getRect(find.text(pair.$1)).bottom),
          reason: pair.$1,
        );
      }
      expect(tester.takeException(), isNull);
    });

    // Short labels on a wide screen, so only the text size can force stacking:
    // 14 * 1.5 = 21 is over the 16 heading size, 14 * 1 = 14 is not.
    for (final scale in [1.0, 1.5]) {
      testWidgets('text scale $scale ${scale > 1 ? 'stacks' : 'keeps'} '
          'the group', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await showGroup(tester, 800, const [
          TicketPaperField(label: 'NAME:', value: 'Juan Dela Cruz'),
          TicketPaperField(label: 'ADDRESS:', value: 'Synthetic Street'),
        ]);
        for (final pair in [
          ('NAME:', 'Juan Dela Cruz'),
          ('ADDRESS:', 'Synthetic Street'),
        ]) {
          final label = tester.getRect(find.text(pair.$1));
          final value = tester.getRect(find.text(pair.$2));
          if (scale > 1) {
            expect(value.top, greaterThan(label.bottom), reason: pair.$1);
          } else {
            expect(value.top, lessThan(label.bottom), reason: pair.$1);
            expect(value.left, greaterThan(label.right), reason: pair.$1);
          }
        }
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('paper sections use one layout per section', () {
    const snapshot = BusinessSnapshot(
      businessAccountNumber: 'TEST-12',
      businessName: 'Synthetic Market Goods',
      registeredOwnerName: 'Synthetic Vendor',
      businessType: 'Public',
      stallNumber: 'A-12',
      marketSectionName: 'Section A',
      businessAddress: '14 Business Lane',
    );
    const registered = VendorSummary(
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
    final ordinance = Ordinance(
      id: 11,
      ordinanceNo: '2026-123456789',
      series: '2026',
      section: '8',
      title: 'Keep market aisles clear',
      description: 'Obstruction',
      category: OrdinanceCategory.sanitation,
      severity: Severity.minor,
      createdAt: DateTime.utc(2026, 10, 7),
      updatedAt: DateTime.utc(2026, 10, 7),
      isActive: true,
      penaltyTierCount: 1,
    );
    final ticket = ticketDetail(
      isTicket: true,
      control: 'TKT-2026-0042',
      snapshot: snapshot,
    );
    final warning = ticketDetail(isTicket: false, control: 'TKT-2026-0042');

    Widget copyCard({required bool isTicket}) => CopyToPaperCard(
      isTicket: isTicket,
      name: 'Juan Dela Cruz',
      address: '31 Synthetic Market Lane',
      place: 'Section A, Stall A-12',
      officerName: 'Pedro Reyes',
      ordinances: [ordinance],
      penaltyType: PenaltyType.cashFine,
      fineTotal: 1500,
      communityHours: null,
      now: DateTime(2026, 11, 7, 9, 5),
    );

    final sections = <String, Widget>{
      'preview violator, ticket': const ViolatorInfoSection(
        vendor: registered,
        isTicket: true,
        personId: 31,
        personFullName: 'Juan Dela Cruz',
        personAddress: '31 Synthetic Market Lane',
        paperViolatorName: 'Juan Dela Cruz',
      ),
      'preview violator, warning': const ViolatorInfoSection(
        vendor: registered,
        isTicket: false,
      ),
      'preview violator, unregistered': const ViolatorInfoSection(
        vendor: null,
        isTicket: true,
      ),
      'preview violation, ticket': ViolationDetailsSection(
        ordinances: [ordinance],
        isTicket: true,
        marketSection: 'Section A',
        description: 'Obstructed aisle',
        issuePlace: 'Fish aisle near F-014',
      ),
      'preview violation, warning': ViolationDetailsSection(
        ordinances: [ordinance],
        isTicket: false,
        marketSection: 'Section A',
        description: 'Obstructed aisle',
      ),
      'preview penalty, cash fine': const PenaltyDetailsSection(
        severity: Severity.moderate,
        penaltyType: PenaltyType.cashFine,
        totalFineAmount: 1500,
        communityHrs: null,
      ),
      'preview penalty, community service': const PenaltyDetailsSection(
        severity: null,
        penaltyType: PenaltyType.communityService,
        totalFineAmount: null,
        communityHrs: 4,
      ),
      'saved violator, reviewed ticket': ViolatorDetailSection(
        ticket: ticket,
        isTicket: true,
      ),
      'saved violator, ticket without history': ViolatorDetailSection(
        ticket: ticketDetail(isTicket: true, control: 'TKT-2026-0042'),
        isTicket: true,
      ),
      'saved violator, warning': ViolatorDetailSection(
        ticket: warning,
        isTicket: false,
      ),
      'saved violator, unregistered': ViolatorDetailSection(
        ticket: ticketDetail(
          isTicket: true,
          control: 'TKT-2026-0042',
          vendorId: null,
        ),
        isTicket: true,
      ),
      'saved violation, ticket': TicketViolationSection(
        violations: ticket.violations,
        description: 'Obstructed aisle',
        marketSection: 'Section A',
        categories: ticket.categories,
        isTicket: true,
        penaltyType: PenaltyType.cashFine,
        issuePlace: 'Fish aisle near F-014',
      ),
      'saved violation, warning': TicketViolationSection(
        violations: warning.violations,
        description: 'Obstructed aisle',
        marketSection: 'Section A',
        categories: warning.categories,
        isTicket: false,
        issuedAt: warning.issuedAt,
      ),
      'ticket copy card': copyCard(isTicket: true),
      'warning copy card': copyCard(isTicket: false),
    };

    // Every group on screen is either fully side by side, with its values on
    // one left edge and one-line labels, or fully stacked. Returns how many
    // groups were side by side.
    int expectGroupsConsistent(WidgetTester tester, String reason) {
      final groups = find.byType(TicketPaperFieldGroup);
      expect(groups, findsWidgets, reason: reason);
      var sideBySideGroups = 0;
      for (var g = 0; g < groups.evaluate().length; g++) {
        final fields = tester
            .widget<TicketPaperFieldGroup>(groups.at(g))
            .fields;
        final texts = find.descendant(
          of: groups.at(g),
          matching: find.byType(Text),
        );
        expect(texts, findsNWidgets(fields.length * 2), reason: reason);
        final labels = <Rect>[];
        final values = <Rect>[];
        for (var i = 0; i < fields.length; i++) {
          labels.add(tester.getRect(texts.at(i * 2)));
          values.add(tester.getRect(texts.at(i * 2 + 1)));
        }
        final stacked = [
          for (var i = 0; i < fields.length; i++)
            values[i].top >= labels[i].bottom,
        ];
        expect(
          stacked.toSet().length,
          1,
          reason: '$reason: group $g mixes stacked and side-by-side rows',
        );
        if (stacked.first) continue;
        sideBySideGroups++;
        final column =
            labels.map((label) => label.right).reduce((a, b) => a > b ? a : b) +
            AppTheme.ticketSmallGap;
        for (var i = 0; i < fields.length; i++) {
          expect(
            labels[i].height,
            closeTo(17.4, 1),
            reason: '$reason: ${fields[i].label} wraps',
          );
          if (fields[i].valueWidget == null) {
            expect(
              values[i].left,
              closeTo(column, 0.5),
              reason: '$reason: ${fields[i].label} is off the value column',
            );
          } else {
            expect(values[i].left, greaterThanOrEqualTo(column - 0.5));
          }
        }
      }
      return sideBySideGroups;
    }

    for (final width in [280.0, 320.0, 360.0, 390.0, 430.0]) {
      testWidgets('every section fits and lines up at ${width}px', (
        tester,
      ) async {
        var sideBySide = 0;
        for (final MapEntry(key: name, value: section) in sections.entries) {
          await showPaper(tester, width, section);
          expect(tester.takeException(), isNull, reason: name);
          sideBySide += expectGroupsConsistent(tester, '$name at ${width}px');
        }
        // 280px is under the breakpoint, so everything stacks; at 430px the
        // 350px sections have room for 'REGISTERED OWNER:' (about 208px) + 12
        // gap + 120 value, so some groups must be side by side.
        if (width == 280) expect(sideBySide, 0);
        if (width == 430) expect(sideBySide, greaterThan(0));
      });
    }

    Future<void> showCard(WidgetTester tester, bool isTicket) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(child: copyCard(isTicket: isTicket)),
          ),
        ),
      );
    }

    // 'NAME & SIGNATURE OF APPREHENDING OFFICER:' is about 500px wide in the
    // test font, far over the card's 350px inside the padding.
    testWidgets('the ticket copy card stacks as a whole at 390px', (
      tester,
    ) async {
      await showCard(tester, true);
      expect(expectGroupsConsistent(tester, 'ticket card'), 0);
      expect(tester.takeException(), isNull);
    });

    // Longest warning label 'Market Enforcer:' is about 196px in the test
    // font; + 12 gap + 120 value = 328, which fits the card's 390 - 40 padding
    // = 350px. Every value starts 12px after that label's right edge.
    testWidgets('the warning copy card is side by side at 390px', (
      tester,
    ) async {
      await showCard(tester, false);
      expect(expectGroupsConsistent(tester, 'warning card'), 1);
      expect(
        tester.getRect(find.text('11/7/2026')).left,
        closeTo(
          tester.getRect(find.text('Market Enforcer:')).right +
              AppTheme.ticketSmallGap,
          0.5,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('paper label colour', () {
    test('is the readable grey', () {
      expect(AppTheme.ticketPaperLabelStyle.color, AppColors.paperLabelGrey);
      expect(AppColors.paperLabelGrey, const Color(0xFF6B6B6B));
    });

    test('has at least 4.5:1 contrast on white and on the page grey', () {
      final luminance = AppTheme.ticketPaperLabelStyle.color!
          .computeLuminance();
      // #6B6B6B: 107/255 = 0.4196 -> ((0.4196 + 0.055) / 1.055)^2.4 = 0.1469.
      // On white (luminance 1): 1.05 / (0.1469 + 0.05) = 5.33.
      // On #F5F5F5 (luminance 0.9129): 0.9629 / 0.1969 = 4.89.
      expect(1.05 / (luminance + 0.05), closeTo(5.33, 0.02));
      expect((0.9129 + 0.05) / (luminance + 0.05), closeTo(4.89, 0.02));
      expect(1.05 / (luminance + 0.05), greaterThanOrEqualTo(4.5));
      expect((0.9129 + 0.05) / (luminance + 0.05), greaterThanOrEqualTo(4.5));
    });
  });
}
