import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/severity.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_hive_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_model.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/fine_breakdown_item.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/fine_summary.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/fine_kind.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_event.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_state.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/bottom_sheets/select_ordinance_bottom_sheet.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/fine_summary_section.dart';
import 'ordinance_shortcuts_test.dart' show withNoShortcuts;
import 'inspection_list_ui_test.dart' show listBloc;
import 'features/auth/data/login_mobile_contract_test.dart' show reply;
import 'features/tickets/data/models/ordinance_model_test.dart'
    show ordinanceResponse;

// Follow-up fixes: hide deactivated ordinances, distinguish same-section entries by title,
// and explain why a ticket total is unavailable.
final _public = <String, Object?>{
  ...ordinanceResponse,
  'id': 19,
  'ordinance_no': '011',
  'series': '2014',
  'section': '79',
  'title': 'Fines / Penalties — Public',
  'category': 'Others',
  'specific_category': 'General Penalties',
  'warning_eligible': true,
};
final _private = <String, Object?>{
  ..._public,
  'id': 20,
  'title': 'Fines / Penalties — Private',
};
final _retired = <String, Object?>{
  ...ordinanceResponse,
  'id': 1,
  'ordinance_no': '145',
  'series': '2006',
  'section': null,
  'title': 'Peace & Order Code',
  'category': 'Noise',
  'is_active': false,
  'warning_eligible': true,
};

FineBreakdownItem _line(
  int id, {
  Severity? severity = Severity.minor,
  FineKind kind = FineKind.fixed,
  double? amount = 500,
}) => FineBreakdownItem(
  ordinanceId: id,
  ordinanceNo: '011',
  section: '79',
  paymentAmount: amount,
  severity: severity,
  offenseNumber: 1,
  isDuplicate: false,
  fineKind: kind,
  minimumFine: kind == FineKind.upTo ? 100 : null,
  maximumFine: kind == FineKind.upTo ? 1000 : null,
  penaltyTerms: kind == FineKind.unconfirmed ? 'Not stated' : null,
);

void main() {
  setUpAll(() {
    final adapter = OrdinanceHiveModelAdapter();
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
  });
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  for (final warning in [true, false]) {
    testWidgets(
      'selection hides inactive ordinances and shows titles (warning=$warning)',
      (tester) async {
        final bloc = await tester.runAsync(
          () => listBloc(
            withNoShortcuts(
              (options) async => reply(options, [_public, _private, _retired]),
            ),
          ),
        );
        await tester.runAsync(() async {
          final loaded = bloc!.stream.firstWhere(
            (s) => s is OrdinanceSelectionLoaded,
          );
          bloc.add(LoadOrdinanceSelection());
          await loaded;
        });
        await tester.pumpWidget(
          BlocProvider<InspectionBloc>.value(
            value: bloc!,
            child: MaterialApp(
              theme: AppTheme.light,
              home: Scaffold(
                body: SelectOrdinanceBottomSheet(
                  isWarningTicket: warning,
                  ordinances: const [],
                  onChanged: (_) {},
                  vendorId: 6,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Ord No. 145'), findsNothing);
        expect(
          find.textContaining('Fines / Penalties — Public'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Fines / Penalties — Private'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  Future<void> pumpSummary(WidgetTester tester, FineSummary summary) async {
    final items = [OrdinanceModel.fromJson(_public).toEntity()];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: FineSummarySection(
              items: items,
              fineSummary: summary,
              isTicket: true,
              onDelete: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('form card shows the ordinance title', (tester) async {
    await pumpSummary(
      tester,
      FineSummary(
        totalPaymentAmount: 500,
        severity: Severity.minor,
        breakdownItems: [_line(19)],
      ),
    );
    expect(find.text('Fines / Penalties — Public'), findsOneWidget);
  });

  testWidgets('missing scoring severity explains the administrator step', (
    tester,
  ) async {
    await pumpSummary(
      tester,
      FineSummary(
        totalPaymentAmount: null,
        severity: null,
        breakdownItems: [_line(19, severity: null)],
      ),
    );
    expect(
      find.text('Unavailable — an administrator must set the scoring severity'),
      findsOneWidget,
    );
    expect(find.text('Unavailable until assessed'), findsNothing);
  });

  testWidgets('unconfirmed penalty explains it is not confirmed', (
    tester,
  ) async {
    await pumpSummary(
      tester,
      FineSummary(
        totalPaymentAmount: null,
        severity: Severity.minor,
        breakdownItems: [_line(19, kind: FineKind.unconfirmed, amount: null)],
      ),
    );
    expect(
      find.text('Unavailable — the penalty is not confirmed'),
      findsOneWidget,
    );
  });

  testWidgets('missing up-to amount keeps the assessment wording', (
    tester,
  ) async {
    await pumpSummary(
      tester,
      FineSummary(
        totalPaymentAmount: null,
        severity: Severity.minor,
        breakdownItems: [_line(19, kind: FineKind.upTo, amount: null)],
      ),
    );
    expect(find.text('Unavailable until assessed'), findsOneWidget);
  });
}
