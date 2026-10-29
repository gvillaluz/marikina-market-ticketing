import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/severity.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ordinance.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ticket_detail.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ticket_detail_content_data.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/violation_summary.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/ordinance_category.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/business_type.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/preview/violation_details_section.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/ticket_detail_content.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/ticket_violation_section.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/ticket_paper_header.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/ticket_paper_field.dart';

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

TicketDetailContent paper({
  required bool isTicket,
  required String control,
  PenaltyType penalty = PenaltyType.cashFine,
}) {
  return TicketDetailContent(
    data: TicketDetailContentData(
      ticket: TicketDetail(
        ticketId: 42,
        controlNumber: isTicket ? control : null,
        enforcerId: 7,
        vendorId: 12,
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
            ordinanceCode: 'SEC-8',
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
  testWidgets('cash ordinance price sits at bottom right of its card', (
    tester,
  ) async {
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
      tester.getBottomRight(price).dy,
      closeTo(tester.getBottomRight(card).dy - 11, 1),
    );
    expect(tester.takeException(), isNull);
  });
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
        for (final control in <String?>[
          null,
          'TKT-2026-00000000000000000042',
        ]) {
          await showPaper(
            tester,
            width,
            MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
              child: TicketPaperHeader(isTicket: true, controlNumber: control),
            ),
          );
          expect(
            find.text(control == null ? 'PENDING' : '#$control'),
            findsOneWidget,
          );
          final title = tester.getRect(find.text('VIOLATION TICKET'));
          final number = tester.getRect(
            find.text(control == null ? 'PENDING' : '#$control'),
          );
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
            child: TicketPaperField(label: 'ADDRESS:', value: address),
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
      if (isTicket) {
        expect(find.text('CONTROL NO.'), findsOneWidget);
        expect(find.text('#TKT-2026-0042'), findsOneWidget);
        expect(find.text('PENDING'), findsNothing);
        // 20px page padding + 20px paper padding puts the right edge at 440.
        expect(
          tester.getTopRight(find.text('#TKT-2026-0042')).dx,
          closeTo(440, 1),
        );
      } else {
        expect(find.text('CONTROL NO.'), findsNothing);
        expect(find.text('#TKT-2026-0042'), findsNothing);
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
      const control = 'TKT-2026-00000000000000000042';
      await showPaper(tester, width, paper(isTicket: true, control: control));
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
    expect(find.text('CONTROL NO.'), findsNothing);
    expect(
      tester.getCenter(find.text('WRITTEN WARNING')).dy,
      closeTo(tester.getCenter(find.byType(Image).first).dy, 1),
    );
    expect(tester.takeException(), isNull);
    await capturePaper(tester, 'paper-warning-280-enlarged');
  });

  for (final width in [280.0, 400.0]) {
    testWidgets('preview ordinance label has a 6px code gap at ${width}px', (
      tester,
    ) async {
      final ordinance = Ordinance(
        id: 11,
        ordinanceNo: '2026-123456789',
        series: '2026',
        marketCode: 'SEC-8',
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
        tester.getTopLeft(find.text('SEC-8')).dy -
            tester.getBottomLeft(label).dy,
        6,
      );
      expect(tester.takeException(), isNull);
      await capturePaper(tester, 'preview-ordinance-${width.toInt()}');
    });
  }
}
