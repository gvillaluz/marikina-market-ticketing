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
import 'package:marikina_market_mobile/features/tickets/domain/entities/inspection_form_data.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_state.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/pages/new_inspection_preview_page.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/preview/photo_evidence_preview_section.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/evidence_gallery_screen.dart';

import 'features/auth/data/login_mobile_contract_test.dart' show reply;
import 'features/tickets/data/models/ordinance_model_test.dart'
    show ordinanceResponse;
import 'fine_summary_display_test.dart' show line, summaryOf;
import 'inspection_list_ui_test.dart' show listBloc;
import 'inspection_preview_navigation_test.dart' show flush, vendor;
import 'review_verify_test.dart' show verifiedAnswer;

// Criterion 6, Submit and Verify again. Viewing a photo on the Review page
// does not undo Verify: after opening and closing the paper ticket photo and
// the supporting photo, Submit is still on and nothing was checked again. The
// network is fake; the test reads which requests the phone made.

const verifiedMessage =
    'Verified. Review the business details, calculated offense positions and '
    'fine before submitting.';
const changedMessage = 'Information changed. Verify again before submitting.';

// The photo screen keeps a loading spinner going, so wait a fixed time for
// the open and close animations instead of waiting for every frame to stop.
Future<void> settle(WidgetTester tester) async {
  for (var frame = 0; frame < 10; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    final adapter = OrdinanceHiveModelAdapter();
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
  });
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('opening and closing the photos keeps Verify and Submit on', (
    tester,
  ) async {
    final folder = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('submit-reverify-'),
    ))!;
    // Windows keeps an open image file locked: let go of the page and the
    // image cache before the photos are deleted.
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      await tester.runAsync(() => folder.delete(recursive: true));
    });
    Future<XFile> photo(String name) async => XFile(
      (await tester.runAsync(
        () => File('assets/logo/org_logo.png').copy('${folder.path}/$name'),
      ))!.path,
    );
    final paper = await photo('paper.png');
    final stall = await photo('stall.png');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      final context = tester.element(find.byType(SizedBox));
      await precacheImage(FileImage(File(paper.path)), context);
      await precacheImage(FileImage(File(stall.path)), context);
    });
    final paths = <String>[];
    final bloc = (await tester.runAsync(
      () => listBloc((options) async {
        paths.add(options.path);
        if (options.path == '/enforcer/tickets/verify') {
          return reply(options, verifiedAnswer());
        }
        throw StateError('Unexpected request: ${options.path}');
      }),
    ))!;
    addTearDown(bloc.close);
    final draft = InspectionFormData(
      vendorSummary: vendor,
      enforcerId: 7,
      personId: 31,
      personFullName: 'Juan Dela Cruz',
      paperViolatorName: 'Juan Cruz',
      paperReference: '000456',
      issuePlace: 'Fish aisle near F-014',
      description: 'Market identification card not displayed',
      ticketType: ViolationType.ticket,
      penaltyType: PenaltyType.cashFine,
      communityServiceHrs: null,
      fineSummary: summaryOf([line(1, '53', 1, amount: 500)], total: 500),
      ordinances: [OrdinanceModel.fromJson(ordinanceResponse).toEntity()],
      paperTicketPhoto: paper,
      evidences: [stall],
    );
    tester.view.physicalSize = const Size(400, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider.value(
          value: bloc,
          child: NewInspectionPreviewPage(formData: draft),
        ),
      ),
    );
    await flush(tester);

    final submit = find.byWidgetPredicate(
      (w) => w is AppPrimaryButton && w.label == 'Submit Ticket',
    );
    final verify = find.byWidgetPredicate(
      (w) => w is AppPrimaryButton && w.label == 'Verify ticket',
    );
    bool submitOn() =>
        tester.widget<AppPrimaryButton>(submit).onPressed != null;

    // Submit starts off; a successful Verify turns it on.
    expect(submitOn(), isFalse);
    await tester.ensureVisible(verify);
    final checked = bloc.stream.firstWhere(
      (state) => state is InspectionVerified,
    );
    await tester.tap(verify);
    await tester.runAsync(() => checked.timeout(const Duration(seconds: 5)));
    await flush(tester);
    expect(submitOn(), isTrue);
    expect(find.text(verifiedMessage), findsOneWidget);

    // Open each photo full screen, then close it. The Review page shows the
    // paper ticket photo first and the supporting photo second.
    final sections = find.byType(PhotoEvidencePreviewSection);
    expect(sections, findsNWidgets(2));
    for (final section in [sections.at(0), sections.at(1)]) {
      final image = find.descendant(of: section, matching: find.byType(Image));
      await tester.ensureVisible(image);
      await tester.tap(image);
      await settle(tester);
      expect(find.byType(EvidenceGalleryScreen), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(EvidenceGalleryScreen),
          matching: find.byIcon(Icons.close),
        ),
      );
      await settle(tester);
      expect(find.byType(EvidenceGalleryScreen), findsNothing);

      // Still verified: Submit on, no "Information changed" message, and
      // viewing did not start another check.
      expect(submitOn(), isTrue);
      expect(find.text(verifiedMessage), findsOneWidget);
      expect(find.text(changedMessage), findsNothing);
      expect(bloc.state, isA<InspectionVerified>());
    }

    // The only request was the one Verify; nothing was saved.
    expect(paths, ['/enforcer/tickets/verify']);
    expect(tester.takeException(), isNull);
  });
}
