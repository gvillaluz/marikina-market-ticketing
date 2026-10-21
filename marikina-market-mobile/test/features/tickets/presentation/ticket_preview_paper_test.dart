import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/preview/violation_details_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/severity.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_hive_model.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/inspection_form_data.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ordinance.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/fine_summary.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/fine_breakdown_item.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/ordinance_category.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/pages/new_inspection_preview_page.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/app_primary_btn.dart';
import '../../../inspection_preview_navigation_test.dart' show vendor;
import '../../../inspection_list_ui_test.dart' show listBloc;
import '../../../features/auth/data/login_mobile_contract_test.dart' show reply;

void main() {
  setUpAll(() {
    final adapter = OrdinanceHiveModelAdapter();
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
  });
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  for (final isTicket in [true, false]) {
    for (final (width, scale, penalty) in [
      for (final penalty
          in (isTicket ? PenaltyType.values : [PenaltyType.cashFine])) ...[
        (280.0, 1.6, penalty),
        (400.0, 1.0, penalty),
      ],
    ]) {
      testWidgets(
        'actual paper preview fits width=$width scale=$scale ticket=$isTicket penalty=${penalty.name}',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final bloc = (await tester.runAsync(
            () => listBloc((options) async => reply(options, [])),
          ))!;
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
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light,
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: BlocProvider<InspectionBloc>.value(
                  value: bloc,
                  child: NewInspectionPreviewPage(
                    formData: InspectionFormData(
                      enforcerId: 7,
                      vendorSummary: vendor,
                      fineSummary: isTicket
                          ? FineSummary(
                              totalPaymentAmount: 1500,
                              severity: Severity.minor,
                              breakdownItems: [
                                FineBreakdownItem(
                                  ordinanceId: 11,
                                  ordinanceNo: '2026-123456789',
                                  ordinanceCode: 'SEC-8',
                                  paymentAmount: 1500,
                                  severity: Severity.minor,
                                  offenseNumber: 1,
                                  isDuplicate: false,
                                ),
                              ],
                            )
                          : null,
                      ordinances: [ordinance],
                      evidences: [],
                      description: 'Obstructed aisle',
                      ticketType: isTicket
                          ? ViolationType.ticket
                          : ViolationType.warning,
                      penaltyType: penalty,
                      communityServiceHrs: null,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('City of Marikina'), findsOneWidget);
          expect(
            find.text('PENDING'),
            isTicket ? findsOneWidget : findsNothing,
          );
          expect(tester.takeException(), isNull);
          await tester.ensureVisible(
            find.text('Ord No. 2026-123456789, Series of 2026'),
          );
          await tester.pumpAndSettle();
          expect(find.text('SEC-8'), findsOneWidget);
          final ordinancePrice = find.descendant(
            of: find.byType(ViolationDetailsSection),
            matching: find.text('₱1,500.00'),
          );
          expect(
            ordinancePrice,
            isTicket && penalty == PenaltyType.cashFine
                ? findsOneWidget
                : findsNothing,
          );
          if (isTicket) {
            await tester.ensureVisible(find.text('No photo evidence'));
            await tester.pumpAndSettle();
            expect(find.text('No photo evidence'), findsOneWidget);
          }
          final action = find.byWidgetPredicate(
            (widget) =>
                widget is AppPrimaryButton &&
                widget.label == (isTicket ? 'Submit Ticket' : 'Submit Warning'),
          );
          await tester.ensureVisible(action);
          await tester.pumpAndSettle();
          expect(action, findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
}
