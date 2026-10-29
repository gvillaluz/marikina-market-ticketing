import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_hive_model.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/verify_inspection_input.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/ordinance_category.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_event.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_state.dart';
import '../../../inspection_list_ui_test.dart' show listBloc;
import '../../auth/data/login_mobile_contract_test.dart' show reply;

const input = VerifyInspectionInput(
  vendorId: 17,
  personId: 31,
  paperViolatorName: 'Juan Cruz',
  description: 'Market aisle obstructed',
  ordinanceIds: [1],
  penaltyType: PenaltyType.cashFine,
  evidenceCount: 1,
);
Map<String, Object?> verified(String snapshot) => {
  'reviewed_calculation': snapshot,
  'calculation': {
    'total_payment_amount': 500,
    'highest_severity': 'Minor',
    'breakdown': [
      {
        'ordinance_id': 1,
        'ordinance_no': '011',
        'ordinance_code': 'SAN',
        'payment_amount': 500,
        'severity': 'Minor',
        'offense_number': 1,
        'is_duplicate': false,
      },
    ],
  },
};
void main() {
  setUpAll(() {
    final adapter = OrdinanceHiveModelAdapter();
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
  });
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test(
    'citation submission preserves reviewed identity through the real use case and multipart boundary',
    () async {
      final original = FlutterImageCompressPlatform.instance;
      FlutterImageCompressPlatform.instance = BoundaryImageCompressor();
      addTearDown(() => FlutterImageCompressPlatform.instance = original);
      final folder = await Directory.systemTemp.createTemp(
        'person-submit-contract-',
      );
      final photo = await File('${folder.path}/synthetic.png').writeAsBytes(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a9ZkAAAAASUVORK5CYII=',
        ),
      );
      addTearDown(() => folder.delete(recursive: true));
      final captured = Completer<Map<String, String>>();
      final bloc = await listBloc((options) async {
        final form = options.data as FormData;
        captured.complete(Map.fromEntries(form.fields));
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response<Object?>(
            requestOptions: options,
            statusCode: 400,
            data: {
              'message':
                  'Synthetic rejection after inspecting the outgoing request.',
            },
          ),
        );
      });
      bloc.add(
        NewInspectionSubmitted(
          personId: 31,
          paperViolatorName: 'Juan Cruz',
          reviewedCalculation: 'server-reviewed-calculation',
          vendorId: 17,
          enforcerId: 7,
          marketSectionId: 1,
          ticketType: ViolationType.ticket,
          ordinanceIds: [1],
          penaltyType: PenaltyType.cashFine,
          communityServiceHours: null,
          description: 'Synthetic market aisle obstruction',
          primaryCategory: <OrdinanceCategory>[],
          evidences: [XFile(photo.path)],
        ),
      );
      final fields = await captured.future.timeout(const Duration(seconds: 5));
      expect(fields['person_id'], '31');
      expect(fields['paper_violator_name'], 'Juan Cruz');
      expect(fields['reviewed_calculation'], 'server-reviewed-calculation');
      expect(fields['vendor_id'], '17');
    },
  );
  test(
    'a new review can verify while the cancelled review response is ignored',
    () async {
      final first = Completer<Response<Object?>>();
      final firstRequest = Completer<RequestOptions>();
      var calls = 0;
      final bloc = await listBloc((options) async {
        expect(options.path, '/enforcer/tickets/verify');
        expect(options.data['vendor_id'], 17);
        expect(options.data['person_id'], 31);
        if (++calls == 1) {
          firstRequest.complete(options);
          return first.future;
        }
        return reply(options, verified('second-review'));
      });
      bloc.add(InspectionVerificationRequested(input));
      final options = await firstRequest.future;
      bloc.invalidateVerification();
      final next = bloc.stream
          .firstWhere((state) => state is InspectionVerified)
          .timeout(const Duration(seconds: 3));
      bloc.add(InspectionVerificationRequested(input));
      try {
        final state = await next as InspectionVerified;
        expect(state.verification.reviewedCalculation, 'second-review');
      } finally {
        first.complete(reply(options, verified('cancelled-review')));
      }
      await Future<void>.delayed(Duration.zero);
      expect(
        (bloc.state as InspectionVerified).verification.reviewedCalculation,
        'second-review',
      );
    },
  );
}

// Native image compression is the only non-network boundary replaced in this test.
class BoundaryImageCompressor extends FlutterImageCompressPlatform {
  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  Future<XFile?> compressAndGetFile(
    String path,
    String targetPath, {
    int minWidth = 1920,
    int minHeight = 1080,
    int inSampleSize = 1,
    int quality = 95,
    int rotate = 0,
    bool autoCorrectionAngle = true,
    CompressFormat format = CompressFormat.jpeg,
    bool keepExif = false,
    int numberOfRetries = 5,
  }) async => null;
}
