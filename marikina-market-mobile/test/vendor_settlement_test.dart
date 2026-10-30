import 'package:marikina_market_mobile/features/records/presentation/widgets/vendor_receipt_section.dart';
import 'package:marikina_market_mobile/features/records/presentation/bloc/vendor_settlement/vendor_settlement_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/shared/data/models/community_service_progress_model.dart';
import 'package:marikina_market_mobile/core/shared/data/models/ticket_receipt_proof_model.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/community_service_log.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/community_service_progress.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/records/data/models/vendor_ticket_detail_model.dart';
import 'package:marikina_market_mobile/features/records/domain/entities/vendor_ticket_detail.dart';
import 'package:marikina_market_mobile/features/records/domain/use_cases/load_vendor_receipt_use_case.dart';
import 'package:marikina_market_mobile/features/records/domain/use_cases/load_vendor_service_progress_use_case.dart';
import 'package:marikina_market_mobile/features/records/presentation/bloc/vendor_settlement/vendor_settlement_bloc.dart';
import 'package:marikina_market_mobile/features/records/presentation/bloc/vendor_settlement/load_vendor_settlement.dart';
import 'package:marikina_market_mobile/features/records/presentation/widgets/vendor_settlement_section.dart';
import 'package:marikina_market_mobile/features/records/presentation/widgets/vendor_record_detail_content.dart';
import 'package:marikina_market_mobile/features/records/presentation/widgets/vendor_service_progress_section.dart';
import 'records_feature_test.dart' show recordsRepository, detailResponse;
import 'features/auth/data/login_mobile_contract_test.dart' show reply;

const receiptResponse = <String, Object?>{
  'ticket_id': 101,
  'penalty_type': 'CashFine',
  'proof_urls': <String>[],
};
const progressResponse = <String, Object?>{
  'ticket_id': 102,
  'hours_required': 8,
  'hours_completed': 2,
  'hours_remaining': 6,
  'completion_percentage': 25,
  'entries': [
    {
      'service_date': '2026-10-13T00:00:00Z',
      'hours_worked': 2,
      'proof_url': 'https://example.com/signed-service-proof-url',
    },
  ],
};
VendorTicketDetail detail({
  String kind = 'CashFine',
  String status = 'Pending',
  int id = 101,
  String type = 'Ticket',
}) => VendorTicketDetailModel.fromJson({
  ...detailResponse,
  'ticket_id': id,
  'type': type,
  'penalty_type': kind,
  'status': status,
}).toEntity();
Future<void> load(VendorSettlementBloc bloc, VendorTicketDetail ticket) async {
  final done = bloc.stream.firstWhere(
    (state) => state.detail != null && !state.isLoading,
  );
  bloc.add(LoadVendorSettlement(ticket));
  await done;
}

void main() {
  setUp(
    () => FlutterSecureStorage.setMockInitialValues({
      'access_token': 'vendor-test-token',
    }),
  );
  for (final kind in ['CashFine', 'BloodDonation']) {
    testWidgets('vendor $kind receipt is read-only without saved proof', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: VendorReceiptSection(
              settlement: VendorSettlementState(
                detail: detail(kind: kind),
                receipt: TicketReceiptProofModel.fromJson({
                  ...receiptResponse,
                  'penalty_type': kind,
                }).toEntity(),
                isLoaded: true,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Attach receipt photo'), findsNothing);
      expect(find.text('Submit receipt'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('warning hides evidence and every settlement section', (
    tester,
  ) async {
    var calls = 0;
    final repository = recordsRepository((options) async {
      calls++;
      return reply(options, receiptResponse);
    });
    late VendorSettlementBloc bloc;
    final warning = detail(type: 'Warning');
    await tester.runAsync(() async {
      bloc = VendorSettlementBloc(
        loadReceipt: LoadVendorReceiptUseCase(repository),
        loadProgress: LoadVendorServiceProgressUseCase(repository),
      );
      await load(bloc, warning).timeout(const Duration(seconds: 5));
    });
    addTearDown(bloc.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  VendorRecordDetailContent(detail: warning),
                  const VendorSettlementSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('WRITTEN WARNING'), findsOneWidget);
    expect(find.text('1st offense'), findsNothing);
    expect(find.text('Photo Evidence Record'), findsNothing);
    expect(find.text('Settlement Receipt'), findsNothing);
    expect(find.text('Community Service Log'), findsNothing);
    expect(find.text('Submit receipt'), findsNothing);
    expect(calls, 0);
    expect(tester.takeException(), isNull);
  });
  test(
    'shared models parse the vendor contracts, including BloodDonation and integer hours',
    () {
      final receipt = TicketReceiptProofModel.fromJson({
        ...receiptResponse,
        'penalty_type': 'BloodDonation',
        'proof_urls': ['https://example.com/signed-receipt-url'],
      }).toEntity();
      expect(receipt.penaltyType.value, 'BloodDonation');
      expect(
        receipt.proofUrls.single,
        'https://example.com/signed-receipt-url',
      );
      final progress = CommunityServiceProgressModel.fromJson(
        progressResponse,
      ).toEntity();
      expect(progress.hoursRemaining, 6);
      expect(progress.completionPercentage, 25);
      expect(progress.entries.single.hoursWorked, 2);
    },
  );
  test(
    'vendor settlement uses GET-only service route and does not load warnings',
    () async {
      final paths = <String>[];
      final repository = recordsRepository((options) async {
        paths.add(options.path);
        expect(options.method, 'GET');
        return reply(options, progressResponse);
      });
      final bloc = VendorSettlementBloc(
        loadReceipt: LoadVendorReceiptUseCase(repository),
        loadProgress: LoadVendorServiceProgressUseCase(repository),
      );
      addTearDown(bloc.close);
      await load(bloc, detail(type: 'Warning'));
      expect(paths, isEmpty);
      await load(bloc, detail(kind: 'CommunityService', id: 102));
      expect(paths, ['/vendor/tickets/102/settlement/community-service']);
      expect(bloc.state.progress!.hoursCompleted, 2);
    },
  );
  testWidgets(
    'paid receipt and service progress fit narrow screens without editing service logs',
    (tester) async {
      tester.view.physicalSize = const Size(280, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = recordsRepository(
        (options) async => reply(options, receiptResponse),
      );
      late VendorSettlementBloc bloc;
      await tester.runAsync(() async {
        bloc = VendorSettlementBloc(
          loadReceipt: LoadVendorReceiptUseCase(repository),
          loadProgress: LoadVendorServiceProgressUseCase(repository),
        );
        await load(
          bloc,
          detail(status: 'Paid'),
        ).timeout(const Duration(seconds: 5));
      });
      addTearDown(bloc.close);
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: MaterialApp(
            theme: AppTheme.light,
            home: MediaQuery(
              data: const MediaQueryData(
                textScaler: TextScaler.linear(2),
                disableAnimations: true,
              ),
              child: const Scaffold(
                body: SingleChildScrollView(child: VendorSettlementSection()),
              ),
            ),
          ),
        ),
      );
      expect(
        find.text('No settlement receipt has been submitted.'),
        findsOneWidget,
      );
      expect(find.text('Submit receipt'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: VendorServiceProgressSection(
                  progress: CommunityServiceProgress(
                    ticketId: 102,
                    hoursRequired: 8,
                    hoursCompleted: 2,
                    hoursRemaining: 6,
                    completionPercentage: 25,
                    entries: [
                      CommunityServiceLog(
                        serviceDate: DateTime.utc(2026, 10, 13),
                        hoursWorked: 2,
                        proofUrl: '',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('2 of 8 hrs completed'), findsOneWidget);
      expect(find.text('6 hrs remaining'), findsOneWidget);
      expect(find.text('Add Service Entry'), findsNothing);
      await tester.tap(find.text('Oct 13, 2026'));
      await tester.pumpAndSettle();
      expect(find.text('10/13/2026'), findsOneWidget);
      expect(find.text('Proof photo unavailable.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
