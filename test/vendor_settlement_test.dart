import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/shared/data/models/community_service_progress_model.dart';
import 'package:marikina_market_mobile/core/shared/data/models/ticket_receipt_proof_model.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/community_service_log.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/community_service_progress.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/ticket_receipt_proof.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/records/data/models/vendor_ticket_detail_model.dart';
import 'package:marikina_market_mobile/features/records/domain/entities/vendor_ticket_detail.dart';
import 'package:marikina_market_mobile/features/records/domain/entities/submit_vendor_receipt_params.dart';
import 'package:marikina_market_mobile/features/records/domain/use_cases/load_vendor_receipt_use_case.dart';
import 'package:marikina_market_mobile/features/records/domain/use_cases/load_vendor_service_progress_use_case.dart';
import 'package:marikina_market_mobile/features/records/domain/use_cases/submit_vendor_receipt_use_case.dart';
import 'package:marikina_market_mobile/features/records/presentation/bloc/vendor_settlement/vendor_settlement_bloc.dart';
import 'package:marikina_market_mobile/features/records/presentation/bloc/vendor_settlement/load_vendor_settlement.dart';
import 'package:marikina_market_mobile/features/records/presentation/bloc/vendor_settlement/submit_vendor_receipt.dart';
import 'package:marikina_market_mobile/features/records/presentation/widgets/vendor_settlement_section.dart';
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

Future<Directory> proofFolder() async {
  final folder = await Directory.systemTemp.createTemp(
    'vendor-settlement-test-',
  );
  addTearDown(() async {
    final target = await folder.resolveSymbolicLinks();
    final root = await Directory.systemTemp.resolveSymbolicLinks();
    if (!target.startsWith('$root${Platform.pathSeparator}')) {
      throw StateError('Unexpected temporary folder.');
    }
    await folder.delete(recursive: true);
  });
  return folder;
}

void main() {
  setUp(
    () => FlutterSecureStorage.setMockInitialValues({
      'access_token': 'vendor-test-token',
    }),
  );
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
        submitReceipt: SubmitVendorReceiptUseCase(repository),
      );
      addTearDown(bloc.close);
      await load(bloc, detail(type: 'Warning'));
      expect(paths, isEmpty);
      await load(bloc, detail(kind: 'CommunityService', id: 102));
      expect(paths, ['/vendor/tickets/102/settlement/community-service']);
      expect(bloc.state.progress!.hoursCompleted, 2);
      expect(bloc.state.canUpload, isFalse);
    },
  );
  test('Paid and previously saved receipts cannot be uploaded', () async {
    var posts = 0;
    var saved = false;
    final repository = recordsRepository((options) async {
      if (options.method == 'POST') posts++;
      return reply(options, {
        ...receiptResponse,
        'proof_urls': saved ? ['https://example.com/saved'] : <String>[],
      });
    });
    final bloc = VendorSettlementBloc(
      loadReceipt: LoadVendorReceiptUseCase(repository),
      loadProgress: LoadVendorServiceProgressUseCase(repository),
      submitReceipt: SubmitVendorReceiptUseCase(repository),
    );
    addTearDown(bloc.close);
    await load(bloc, detail(status: 'Paid'));
    bloc.add(const SubmitVendorReceipt('unused.png'));
    await Future<void>.delayed(Duration.zero);
    expect(posts, 0);
    saved = true;
    await load(bloc, detail());
    expect(bloc.state.canUpload, isFalse);
    bloc.add(const SubmitVendorReceipt('unused.png'));
    await Future<void>.delayed(Duration.zero);
    expect(posts, 0);
  });
  test(
    'one multipart upload locks proof and preserves the ticket status',
    () async {
      final folder = await proofFolder();
      final photo = await File(
        'assets/logo/org_logo.png',
      ).copy('${folder.path}/proof.png');
      final request = Completer<RequestOptions>();
      final pending = Completer<Response<Object?>>();
      var posts = 0;
      final repository = recordsRepository((options) async {
        if (options.method == 'GET') return reply(options, receiptResponse);
        posts++;
        request.complete(options);
        return pending.future;
      });
      final bloc = VendorSettlementBloc(
        loadReceipt: LoadVendorReceiptUseCase(repository),
        loadProgress: LoadVendorServiceProgressUseCase(repository),
        submitReceipt: SubmitVendorReceiptUseCase(repository),
      );
      addTearDown(bloc.close);
      await load(bloc, detail());
      final saved = bloc.stream.firstWhere((state) => state.hasUploaded);
      bloc.add(SubmitVendorReceipt(photo.path));
      final options = await request.future;
      bloc.add(SubmitVendorReceipt(photo.path));
      await Future<void>.delayed(Duration.zero);
      expect(posts, 1);
      expect(options.path, '/vendor/tickets/101/settlement/receipt');
      expect(options.headers['Authorization'], 'Bearer vendor-test-token');
      expect(options.contentType, startsWith('multipart/form-data'));
      final form = options.data as FormData;
      expect(form.fields, isEmpty);
      expect(form.files.single.key, 'proof_file');
      expect(form.files.single.value.contentType.toString(), 'image/png');
      pending.complete(
        reply(options, {
          ...receiptResponse,
          'proof_urls': ['https://example.com/signed-receipt-url'],
        }),
      );
      await saved;
      expect(bloc.state.detail!.status, TicketStatus.pending);
      expect(bloc.state.canUpload, isFalse);
      bloc.add(SubmitVendorReceipt(photo.path));
      await Future<void>.delayed(Duration.zero);
      expect(posts, 1);
    },
  );
  test(
    'invalid type, disguised files, and files over 5 MB never reach HTTP',
    () async {
      final folder = await proofFolder();
      final invalid = File('${folder.path}/invalid.png');
      await invalid.writeAsBytes([1, 2, 3]);
      final oversized = File('${folder.path}/large.jpg');
      final handle = await oversized.open(mode: FileMode.write);
      await handle.truncate(5 * 1024 * 1024 + 1);
      await handle.close();
      final gif = File('${folder.path}/invalid.gif');
      await gif.writeAsBytes([71, 73, 70]);
      var calls = 0;
      final repository = recordsRepository((options) async {
        calls++;
        return reply(options, receiptResponse);
      });
      for (final path in [invalid.path, oversized.path, gif.path]) {
        expect(
          await repository.submitReceipt(
            SubmitVendorReceiptParams(ticketId: 101, filePath: path),
          ),
          isA<ResultFailure<TicketReceiptProof>>(),
        );
      }
      expect(calls, 0);
    },
  );
  test(
    'unconfirmed upload requires fresh proof loading before a retry',
    () async {
      final folder = await proofFolder();
      final photo = await File(
        'assets/logo/org_logo.png',
      ).copy('${folder.path}/proof.png');
      var posts = 0;
      var stored = false;
      final repository = recordsRepository((options) async {
        if (options.method == 'POST') {
          posts++;
          stored = true;
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          );
        }
        return reply(options, {
          ...receiptResponse,
          'proof_urls': stored ? ['https://example.com/saved'] : <String>[],
        });
      });
      final bloc = VendorSettlementBloc(
        loadReceipt: LoadVendorReceiptUseCase(repository),
        loadProgress: LoadVendorServiceProgressUseCase(repository),
        submitReceipt: SubmitVendorReceiptUseCase(repository),
      );
      addTearDown(bloc.close);
      await load(bloc, detail());
      final failed = bloc.stream.firstWhere(
        (state) => state.uploadError != null,
      );
      bloc.add(SubmitVendorReceipt(photo.path));
      await failed;
      expect(bloc.state.canUpload, isFalse);
      bloc.add(SubmitVendorReceipt(photo.path));
      await Future<void>.delayed(Duration.zero);
      expect(posts, 1);
      await load(bloc, detail());
      expect(bloc.state.receipt!.proofUrls, hasLength(1));
      expect(bloc.state.canUpload, isFalse);
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
      final bloc = VendorSettlementBloc(
        loadReceipt: LoadVendorReceiptUseCase(repository),
        loadProgress: LoadVendorServiceProgressUseCase(repository),
        submitReceipt: SubmitVendorReceiptUseCase(repository),
      );
      addTearDown(bloc.close);
      await tester.runAsync(() => load(bloc, detail(status: 'Paid')));
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
        find.text('This ticket is paid. Settlement details are read-only.'),
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
